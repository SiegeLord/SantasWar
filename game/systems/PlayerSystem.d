module game.systems.PlayerSystem;

import game.System;
import game.IGame;
import game.GameObject;

import game.components.Bool;
import game.components.Vector;
import game.components.AnimationSet;
import game.components.Direction;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;

class CPlayerSystem : CSystem
{
	this(IGame game)
	{
		Game = game;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector DrawPosition;
		CAnimationSet Animation;
		CDirection Direction;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CBool is_player;
		CVector draw_position;
		CAnimationSet animation;
		CDirection direction;
		if(object.Get("is_player", is_player) &&
		   object.Get("draw_position", draw_position) &&
		   object.Get("direction", direction) &&
		   object.Get("animation", animation))
		{
			if(is_player.Value)
			{
				Refs ~= SObject(object, draw_position, animation, direction);
				animation.Load(Game);
				object.DeathEvent.Register(&RemoveObject);
			}
		}
	}
	
	override
	void Draw()
	{
		foreach(obj; Refs)
		{
			obj.Animation.GetSprite(Game.Time, obj.Direction).Draw(Game.Time, obj.DrawPosition.X * TileSize, obj.DrawPosition.Y * TileSize);
			//al_draw_filled_rectangle(obj.DrawPosition.X * TileSize, obj.DrawPosition.Y * TileSize, obj.DrawPosition.X * TileSize + TileSize, obj.DrawPosition.Y * TileSize + TileSize, al_map_rgb_f(1, 0, 1));
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
}
