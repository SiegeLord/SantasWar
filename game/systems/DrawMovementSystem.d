module game.systems.DrawMovementSystem;

import game.System;
import game.IGame;
import game.GameObject;

import game.components.Bool;
import game.components.Vector;
import game.components.Float;
import game.components.Direction;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;
import tango.math.Math;

class CDrawMovementSystem : CSystem
{
	this(IGame game)
	{
		Game = game;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector OldPosition;
		CVector Position;
		CVector DrawPosition;
		CDirection Direction;
		CFloat MoveInterval;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector old_position;
		CVector position;
		CVector draw_position;
		CDirection direction;
		CFloat move_interval;

		if(object.Get("old_position", old_position) &&
		   object.Get("position", position) &&
		   object.Get("draw_position", draw_position) &&
		   object.Get("move_interval", move_interval) &&
		   object.Get("direction", direction))
		{
			Refs ~= SObject(object, old_position, position, draw_position, direction, move_interval);
			draw_position.Value.Set(-1, -1);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
	
	override
	void Logic(float dt)
	{
		foreach(obj; Refs)
		{
			if(abs(obj.Position.X - obj.DrawPosition.X) > 1.0 || abs(obj.Position.Y - obj.DrawPosition.Y) > 1.0)
			{
				obj.DrawPosition.Value = obj.OldPosition.Value;
			}
			
			if((obj.OldPosition.Value - obj.Position.Value).LengthSq > 0.1)
			{
				if(obj.Position.X - obj.OldPosition.X > 0.1)
				{
					obj.DrawPosition.Y = obj.Position.Y;
					obj.DrawPosition.X += dt / obj.MoveInterval.Value;
				}
				else if(obj.Position.X - obj.OldPosition.X < -0.1)
				{
					obj.DrawPosition.Y = obj.Position.Y;
					obj.DrawPosition.X -= dt / obj.MoveInterval.Value;
				}
				else if(obj.Position.Y - obj.OldPosition.Y > 0.1)
				{
					obj.DrawPosition.X = obj.Position.X;
					obj.DrawPosition.Y += dt / obj.MoveInterval.Value;
				}
				else if(obj.Position.Y - obj.OldPosition.Y < -0.1)
				{
					obj.DrawPosition.X = obj.Position.X;
					obj.DrawPosition.Y -= dt / obj.MoveInterval.Value;
				}
				
				if((obj.DrawPosition.Value - obj.OldPosition.Value).LengthSq > 1.0)
					obj.DrawPosition.Value = obj.Position.Value;
			}
			else
			{
				obj.DrawPosition.Value = obj.OldPosition.Value;
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
	IGame Game;
	SObject[] Refs;
}
