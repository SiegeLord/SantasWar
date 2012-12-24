module game.Server;

import game.Channel;
import game.Disposable;
import game.IMessage;
import game.Simulation;
import game.IGame;
import game.ObjectController;
import game.GameObject;
import game.UnorderedEvent;

import game.messages.InputMessage;
import game.messages.StateMessage;
import game.messages.NameMessage;
import game.messages.MapInitMessage;
import game.messages.UIMessage;

import game.components.Vector;
import game.components.Float;

import tango.core.Array;
import tango.io.Stdout;
import tango.text.convert.Format;
import tango.io.stream.Data;

enum SyncInterval = 1.0 / 15;

class CServer : CDisposable
{
	this(IGame game)
	{
		Game = game;
		Simulation = new CSimulation(game, true);
		Simulation.CreateMap(Game.Map);
		Simulation.ObjectAddedEvent.Register(&ObjectAdded);
		Simulation.ObjectRemovedEvent.Register(&ObjectRemoved);
		
		TeamCounts[] = 0;
		TeamScores[] = 0;
		MatchTime = Game.MatchDuration * 60;
		MatchEndedEvent = new typeof(MatchEndedEvent);
	}
	
	class CPlayer
	{
		this(CChannel channel, size_t idx, int team)
		{
			Channel = channel;
			PlayerIdx = idx;
			Channel.ReceiveEvent.Register(&Receiver);
			Controller = new CObjectController(Format("Player {}", idx));
			Controller.DeathEvent.Register( { if(Resolution == EGameResolution.NotDone) TeamScores[1 - Team]++; } );
			Team = team;
		}
		
		void Receiver(IMessage message)
		{
			PlayerMessage(message, PlayerIdx);
		}
		
		void SetObject(CGameObject object)
		{
			Controller.SetObject(object);
		}
	protected:
		bool New = true;
		CObjectController Controller;
		CChannel Channel;
		size_t PlayerIdx;
		int Team;
	}
	
	void AddPlayer(CChannel channel)
	{
		int team;
		if(TeamCounts[1] < TeamCounts[0])
			team = 1;
		else
			team = 0;
		
		TeamCounts[team]++;
		
		Players ~= new CPlayer(channel, Players.length, team);
		
		Respawn(Players[$ - 1], team);
	}
	
	void Respawn(CPlayer player, int team = -1)
	{
		auto spot = Simulation.GetSpawnSpot();
		
		if(team == -1)
			team = player.Team;
		
		auto id = player.Controller.GameObjectId;
		if(id >= 0)
			Simulation.RemoveObject(id);
		
		auto obj = Simulation.AddObject(team == 0 ? "objects/red_player.cfg" : "objects/blue_player.cfg");
		
		CVector position;
		CVector old_position;
		CFloat team_comp;
		
		if(obj.Get("position", position))
			position.Value = spot;
		
		if(obj.Get("old_position", old_position))
			old_position.Value = spot;
		
		if(obj.Get("team", team_comp))
			team_comp.Value = team < 0 ? player.Team : team;
		
		player.Controller.SetObject(obj);
	}
	
	void RemovePlayer(CChannel channel)
	{
		auto new_length = Players.partition((CPlayer player) => player.Channel != channel);
		if(new_length != Players.length)
		{
			auto id = Players[$-1].Controller.GameObjectId;
			if(id >= 0)
				Simulation.RemoveObject(id);
			
			TeamCounts[Players[$-1].Team]--;
			TeamScores[1 - Players[$-1].Team]--; // To counteract the increase from DC'ing
			
			Players.length = new_length;
		}
	}
	
	void PlayerMessage(IMessage message, size_t idx)
	{
		switch(message.Type)
		{
			case EMessageType.Input:
				auto input_mess = cast(CInputMessage)message;
				Players[idx].Controller.Input(input_mess.Input, input_mess.Down);
				if(input_mess.Input == EInput.Respawn)
					Respawn(Players[idx]);
				break;
			case EMessageType.Name:
				auto name_mess = cast(CNameMessage)message;
				Players[idx].Controller.PlayerName = name_mess.Name;
				break;
			default: {}
		}
	}
	
	void Logic(float dt)
	{
		Simulation.Logic(dt);
		if(Players.length > 1)
			MatchTime -= dt;
		
		if(MatchTime < 0)
		{
			MatchTime = 0;
			
			if(Resolution == EGameResolution.NotDone)
			{
				if(TeamScores[0] > TeamScores[1])
					Resolution = EGameResolution.RedWins;
				else if(TeamScores[1] > TeamScores[0])
					Resolution = EGameResolution.BlueWins;
				
				if(Resolution != EGameResolution.NotDone)
					MatchEndedEvent.Trigger();
			}
		}
		
		if(Game.Time > NextSyncTime)
		{
			NextSyncTime += SyncInterval;
			
			bool need_new = false;
			/* For existing players */
			{
				scope state_message = new CStateMessage;
				
				auto data = new DataOutput(state_message.StateArray);
				
				/* New objects */
				data.int32(cast(int)AddedObjects.length);
				foreach(obj; AddedObjects)
				{
					data.array(obj.Name);
					data.int32(obj.Id);
				}
				AddedObjects.length = 0;
				
				/* Removed objects */
				data.int32(cast(int)RemovedObjects.length);
				foreach(obj; RemovedObjects)
					data.int32(obj.Id);
				RemovedObjects.length = 0;
				
				/* New state */
				Simulation.SaveState(data);
				
				data.flush();
				
				foreach(player; Players)
				{
					if(!player.New)
						player.Channel.Send(state_message);
					else
						need_new = true;
				}
			}
			
			/* For new players */
			if(need_new)
			{
				scope map_message = new CMapInitMessage;
				map_message.Width = Simulation.TileMap.Width;
				map_message.Height = Simulation.TileMap.Height;
				map_message.TileMap = Simulation.TileMap.TileMap;

				scope state_message = new CStateMessage;
				
				auto data = new DataOutput(state_message.StateArray);
				
				/* Send everything */
				data.int32(cast(int)Simulation.SyncObjects.length);
				foreach(obj; Simulation.SyncObjects)
				{
					data.array(obj.Name);
					data.int32(obj.Id);
				}
				
				/* Nothing to remove yet */
				data.int32(0);
				
				/* New state */
				Simulation.SaveState(data);
				
				data.flush();
				
				foreach(player; Players)
				{
					if(player.New)
					{
						player.Channel.Send(map_message);
						player.Channel.Send(state_message);
						player.New = false;
					}
				}
			}
			
			scope ui_message = new CUIMessage;
			ui_message.RedScore = TeamScores[0];
			ui_message.BlueScore = TeamScores[1];
			ui_message.MatchTime = MatchTime;
			ui_message.Resolution = Resolution;
			
			foreach(player; Players)
			{
				int id = player.Controller.GameObjectId();
				if(id >= 0)
				{
					auto obj = Simulation.GetObject(id);
					if(obj !is null)
					{
						CFloat health;
						if(obj.Get("health", health))
							ui_message.Health = cast(int)health.Value;
						else
							ui_message.Health = -1;
							
						CFloat ammo;
						if(obj.Get("ammo", ammo))
							ui_message.Ammo = cast(int)ammo.Value;
						else
							ui_message.Ammo = 0;
					}
					else
					{
						ui_message.Health = -1;
					}
				}
				else
				{
					ui_message.Health = -1;
				}
				
				player.Channel.Send(ui_message);
			}
		}
	}
	
	CUnorderedEvent!() MatchEndedEvent;
protected:
	EGameResolution Resolution = EGameResolution.NotDone;
	CGameObject[] AddedObjects;
	CGameObject[] RemovedObjects;
	int[2] TeamCounts;
	int[2] TeamScores;
	float MatchTime;
	
	void ObjectAdded(CGameObject object)
	{
		AddedObjects ~= object;
	}
	
	void ObjectRemoved(CGameObject object)
	{
		//Stdout("Server removed", object.Id).nl;
		RemovedObjects ~= object;
	}
	
	float NextSyncTime = 0.0;
	CSimulation Simulation;
	CPlayer[] Players;
	IGame Game;
}
