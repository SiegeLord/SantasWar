module game.systems.DrawSnowballSystem;

import game.System;
import game.IGame;
import game.GameObject;
import game.MathTypes;
import game.ISimulation;
import game.Bitmap;

import game.components.Bool;
import game.components.Vector;
import game.components.Direction;
import game.components.Float;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;
import tango.math.Math;

class CDrawSnowballSystem : CSystem
{
	this(IGame game, ISimulation sim)
	{
		Simulation = sim;
		Snowball = game.BitmapManager.Load("bitmaps/snowball.png");
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector Position;
		CDirection Direction;
		CFloat Life;
		CFloat HorizontalSpeed;
		CFloat VerticalVelocity;
		CFloat Altitude;
		CFloat Power;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CBool draw_snowball;
		CVector position;
		CDirection direction;
		CFloat life;
		CFloat vertical_velocity;
		CFloat altitude;
		CFloat horizontal_speed;
		CFloat power;

		if(object.Get("draw_snowball", draw_snowball) &&
		   object.Get("position", position) &&
		   object.Get("direction", direction) &&
		   object.Get("life", life) &&
		   object.Get("power", power) &&
		   object.Get("vertical_velocity", vertical_velocity) &&
		   object.Get("altitude", altitude) &&
		   object.Get("horizontal_speed", horizontal_speed))
		{
			if(draw_snowball.Value)
			{
				Refs ~= SObject(object, position, direction, life, horizontal_speed, vertical_velocity, altitude, power);
				object.DeathEvent.Register(&RemoveObject);
			}
		}
	}
	
	override
	void Logic(float dt)
	{
		foreach(obj; Refs)
		{
			if(obj.Life.Value < dt)
				obj.VerticalVelocity.Value = obj.Power.Value;
			obj.Life.Value += dt;
			obj.VerticalVelocity.Value -= dt;
			obj.Altitude.Value += obj.VerticalVelocity * dt;
		}
	}
		
	override
	void Draw()
	{
		foreach(obj; Refs)
		{
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
			
			float alt = max(obj.Altitude.Value / 4, 0);
			float shadow_alt = min(alt, cast(float)Simulation.GetHeight(cast(int)pos.X, cast(int)pos.Y) / 4);

			al_draw_filled_circle(pos.X * TileSize, (pos.Y - shadow_alt) * TileSize, 2, al_map_rgb_f(0.1, 0.1, 0.3));
			//al_draw_filled_circle(pos.X * TileSize, (pos.Y - alt) * TileSize, 2, al_map_rgb_f(0, 1, 1));
			
			auto bw = al_get_bitmap_width(Snowball.Get);
			auto bh = al_get_bitmap_height(Snowball.Get);
			al_draw_bitmap(Snowball.Get, pos.X * TileSize - bw / 2, (pos.Y - alt) * TileSize - bh / 2, 0);
		}
	}
	
	override
	void RemoveObject(CGameObject object)
	{
		size_t new_size = Refs.partition((SObject holder) => holder.GameObject !is object);
		Refs.length = new_size;
	}
protected:
	CBitmap Snowball;
	SObject[] Refs;
	ISimulation Simulation;
}
