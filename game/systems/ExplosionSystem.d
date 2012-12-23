module game.systems.ExplosionSystem;

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

class CExplosionSystem : CSystem
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
		CFloat ExplosionDuration;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector position;
		CFloat explosion_duration;

		if(object.Get("position", position) &&
		   object.Get("explosion_duration", explosion_duration))
		{		
			Refs ~= SObject(object, position, explosion_duration);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
		
	override
	void Logic(float dt)
	{
		scope SObject[] to_remove;
		
		foreach(obj; Refs)
		{
			obj.ExplosionDuration.Value -= dt;
			if(obj.ExplosionDuration.Value < 0)
				to_remove ~= obj;
		}
		
		foreach(obj; to_remove)
		{
			Simulation.RemoveObject(obj.GameObject.Id);
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
