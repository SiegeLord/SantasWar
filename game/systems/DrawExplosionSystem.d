module game.systems.DrawExplosionSystem;

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
import game.components.Explosion;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;
import tango.math.Math;

class CDrawExplosionSystem : CSystem
{
	this(IGame game)
	{
		Game = game;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector Position;
		CExplosion Explosion;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector position;
		CExplosion explosion;

		if(object.Get("position", position) &&
		   object.Get("explosion", explosion))
		{
			explosion.Load(Game);	
			explosion.Sprite.TimeOffset = Game.Time;	
			Refs ~= SObject(object, position, explosion);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
		
	override
	void Draw()
	{
		foreach(obj; Refs)
		{
			obj.Explosion.Sprite.Draw(Game.Time, obj.Position.X * TileSize, obj.Position.Y * TileSize);
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
