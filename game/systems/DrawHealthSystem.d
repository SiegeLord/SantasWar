module game.systems.DrawHealthSystem;

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

class CDrawHealthSystem : CSystem
{
	this(IGame game)
	{
		Health = game.BitmapManager.Load("bitmaps/health.png");
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector Position;
		CBool Exists;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CBool draw_health;
		CVector position;
		CBool exists;

		if(object.Get("draw_health", draw_health) &&
		   object.Get("position", position) &&
		   object.Get("exists", exists))
		{
			if(draw_health.Value)
			{
				Refs ~= SObject(object, position, exists);
				object.DeathEvent.Register(&RemoveObject);
			}
		}
	}
		
	override
	void Draw()
	{
		foreach(obj; Refs)
		{
			if(obj.Exists.Value)
			{
				//al_draw_filled_circle((obj.Position.X + 0.5) * TileSize, (obj.Position.Y + 0.5) * TileSize, 3, al_map_rgb_f(0.4, 0.1, 0.1));
				al_draw_bitmap(Health.Get, obj.Position.X * TileSize, obj.Position.Y * TileSize, 0);
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
	CBitmap Health;
}
