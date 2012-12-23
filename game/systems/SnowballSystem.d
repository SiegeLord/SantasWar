module game.systems.SnowballSystem;

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
import Random = tango.math.random.Random;

class CSnowballSystem : CSystem
{
	this(IGame game, ISimulation sim)
	{
		Simulation = sim;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector Position;
		CDirection Direction;
		CFloat Life;
		CFloat HorizontalSpeed;
		CFloat Power;
		CFloat Altitude;
		CFloat VerticalVelocity;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CBool is_snowball;
		CVector position;
		CDirection direction;
		CFloat life;
		CFloat horizontal_speed;
		CFloat power;
		CFloat altitude;
		CFloat vertical_velocity;

		if(object.Get("is_snowball", is_snowball) &&
		   object.Get("position", position) &&
		   object.Get("direction", direction) &&
		   object.Get("life", life) &&
		   object.Get("power", power) &&
		   object.Get("altitude", altitude) &&
		   object.Get("vertical_velocity", vertical_velocity) &&
		   object.Get("horizontal_speed", horizontal_speed))
		{
			if(is_snowball.Value)
			{
				Refs ~= SObject(object, position, direction, life, horizontal_speed, power, altitude, vertical_velocity);
				object.DeathEvent.Register(&RemoveObject);
			}
		}
	}
	
	override
	void Logic(float dt)
	{
		scope SObject[] to_remove;
		foreach(obj; Refs)
		{
			obj.Life.Value += dt;
			obj.VerticalVelocity.Value -= dt;
			obj.Altitude.Value += obj.VerticalVelocity * dt;
			
			SVector2D dir;
			final switch(obj.Direction.Value)
			{
				case EDirection.Up:
					dir.Set(0, -1);
					break;
				case EDirection.Down:
					dir.Set(0, 1);
					break;
				case EDirection.Left:
					dir.Set(-1, 0);
					break;
				case EDirection.Right:
					dir.Set(1, 0);
					break;
			}
			dir *= obj.HorizontalSpeed.Value * obj.Life.Value;
			
			auto pos = obj.Position.Value + dir;
			
			auto height = Simulation.GetHeight(cast(int)pos.X, cast(int)pos.Y);
			
			if(obj.Altitude.Value < height)
			{
				to_remove ~= obj;
				Simulation.Damage(cast(int)pos.X, cast(int)pos.Y, obj.Power.Value * 50);
				
				auto explosion = Simulation.AddObject("objects/snowball_splat.cfg");
				CVector position;
				if(explosion.Get("position", position))
					position.Value = pos - SVector2D(0.5, 0.5);
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
