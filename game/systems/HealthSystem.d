module game.systems.HealthSystem;

import game.System;
import game.IGame;
import game.GameObject;
import game.MathTypes;
import game.ISimulation;

import game.components.Bool;
import game.components.Vector;
import game.components.Direction;
import game.components.Float;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;
import tango.math.Math;

class CHealthSystem : CSystem
{
	this(IGame game, ISimulation sim)
	{
		Game = game;
		Simulation = sim;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector Position;
		CBool Exists;
		CFloat RespawnTime;
		CFloat RespawnInterval;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CBool is_health;
		CVector position;
		CFloat respawn_time;
		CFloat respawn_interval;
		CBool exists;

		if(object.Get("is_health", is_health) &&
		   object.Get("position", position) &&
		   object.Get("respawn_time", respawn_time) &&
		   object.Get("respawn_interval", respawn_interval) &&
		   object.Get("exists", exists))
		{
			if(is_health.Value)
			{
				Refs ~= SObject(object, position, exists, respawn_time, respawn_interval);
				object.DeathEvent.Register(&RemoveObject);
			}
		}
	}
		
	override
	void Logic(float dt)
	{
		foreach(obj; Refs)
		{
			if(Game.Time > obj.RespawnTime.Value)
			{
				if(Simulation.GetHeight(cast(int)obj.Position.X, cast(int)obj.Position.Y) > 0)
				{
					Simulation.Damage(cast(int)obj.Position.X, cast(int)obj.Position.Y, -50);
					obj.RespawnTime = Game.Time + obj.RespawnInterval.Value;
					obj.Exists.Value = false;
					auto explosion = Simulation.AddObject("objects/candy_splat.cfg");
					CVector position;
					if(explosion.Get("position", position))
						position.Value = obj.Position.Value;
				}
				else
				{
					obj.Exists.Value = true;
				}
			}
		}
	}
	
	override
	void RemoveObject(CGameObject object)
	{
		size_t new_size = Refs.partition((SObject holder) => holder.GameObject !is object);
		Refs.length = new_size;
	}
protected:
	SObject[] Refs;
	IGame Game;
	ISimulation Simulation;
}
