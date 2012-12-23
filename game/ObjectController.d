module game.ObjectController;

import game.GameObject;
import game.UnorderedEvent;

import game.components.Bool;
import game.components.Vector;
import game.components.String;
import game.components.Direction;

import game.messages.InputMessage;

import tango.io.Stdout;

class CObjectController
{
	this(const(char)[] player_name)
	{
		PlayerName = player_name;
		DeathEvent = new typeof(DeathEvent);
	}
	
	void SetObject(CGameObject object)
	{
		if(object.Get("desired_direction", DesiredDirection) &&
		   object.Get("want_move", WantMove) &&
		   object.Get("want_collect", WantCollect) &&
		   object.Get("want_charge", WantCharge))
		{
			GameObject = object;
			object.DeathEvent.Register((_) {GameObject = null; DeathEvent.Trigger(); });
		}
		
		if(object.Get("name", Name))
		{
			Name.Value = PlayerName;
		}
	}
	
	@property
	void PlayerName(const(char)[] name)
	{
		if(name != "")
		{
			PlayerNameVal = name;
			
			if(Name !is null)
				Name.Value = PlayerName;
		}
	}
	
	@property
	const(char)[] PlayerName()
	{
		return PlayerNameVal;
	}
	
	void Input(EInput input, bool down)
	{
		if(!GameObject)
			return;
		
		switch(input)
		{
			case EInput.Up:
				if(down)
					DesiredDirection.Value = EDirection.Up;
				Up = down;
				break;
			case EInput.Down:
				if(down)
					DesiredDirection.Value = EDirection.Down;
				Down = down;
				break;
			case EInput.Left:
				if(down)
					DesiredDirection.Value = EDirection.Left;
				Left = down;
				break;
			case EInput.Right:
				if(down)
					DesiredDirection.Value = EDirection.Right;
				Right = down;
				break;
			case EInput.Launch:
				Launch = down;
				break;
			case EInput.Collect:
				Collect = down;
				break;
			default: {}
		}

		WantCharge.Value = Launch;
		WantCollect.Value = Collect;
		
		if(Up || Down || Left || Right)
			WantMove.Value = true;
		else
			WantMove.Value = false;
		
		if(!down)
		{
			int net_x = (Left ? -1 : 0) + (Right ? 1 : 0);
			int net_y = (Up ? -1 : 0) + (Down ? 1 : 0);
			
			if(net_x)
			{
				if(net_y)
					DesiredDirection.Value = net_x > 0 ? EDirection.Right : EDirection.Left;
				else
					DesiredDirection.Value = net_x > 0 ? EDirection.Right : EDirection.Left;
			}
			else
			{
				if(net_y)
					DesiredDirection.Value = net_y > 0 ? EDirection.Down : EDirection.Up;
				else
					WantMove.Value = false;
			}
		}
	}
	
	@property
	int GameObjectId()
	{
		if(GameObject !is null)
			return GameObject.Id;
		else
			return -1;
	}
	
	CUnorderedEvent!() DeathEvent;
protected:
	bool Up, Down, Left, Right, Launch, Collect;
	const(char)[] PlayerNameVal;
	CGameObject GameObject;
	CString Name;
	CDirection DesiredDirection;
	CBool WantMove;
	CBool WantCharge;
	CBool WantCollect;
}
