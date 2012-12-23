module game.systems.DamageSystem;

import game.System;
import game.IGame;
import game.ISimulation;
import game.GameObject;
import game.MathTypes;

import game.components.Bool;
import game.components.Vector;
import game.components.Float;
import game.components.Direction;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;
import tango.math.Math;

class CDamageSystem : CSystem
{
	this(IGame game, ISimulation sim)
	{
		Simulation = sim;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector Position;
		CFloat Health;
		CFloat Team;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector position;
		CFloat health;
		CFloat team;

		if(object.Get("health", health) &&
		   object.Get("team", team) &&
		   object.Get("position", position))
		{
			Refs ~= SObject(object, position, health, team);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
	
	void Damage(int x, int y, float damage)
	{
		auto pos = SVector2D(x, y);
		
		scope SObject[] to_remove;
		
		foreach(obj; Refs)
		{
			if((obj.Position - pos).LengthSq() < 0.1)
			{
				obj.Health.Value -= damage;
				if(obj.Health.Value < 0)
				{
					to_remove ~= obj;
					auto explosion = Simulation.AddObject(obj.Team.Value < 0.1 ? "objects/red_body.cfg" : "objects/blue_body.cfg");
					CVector position;
					if(explosion.Get("position", position))
						position.Value = obj.Position.Value;
				}
				if(obj.Health.Value > 100)
					obj.Health.Value = 100;
				break;
			}
		}
		
		foreach(obj; to_remove)
			Simulation.RemoveObject(obj.GameObject.Id);
	}
	
	override
	void RemoveObject(CGameObject object)
	{
		size_t new_size = Refs.partition((SObject holder) => holder.GameObject !is object);
		Refs.length = new_size;
	}
protected:
	ISimulation Simulation;
	SObject[] Refs;
}
