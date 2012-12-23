module game.systems.CollisionSystem;

import game.System;
import game.IGame;
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

class CCollisionSystem : CSystem
{
	this(IGame game)
	{
		Game = game;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector Position;
		CFloat Height;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector position;
		CFloat height;

		if(object.Get("height", height) &&
		   object.Get("position", position))
		{
			Refs ~= SObject(object, position, height);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
	
	int GetHeight(int x, int y)
	{
		int ret = 0;
		auto pos = SVector2D(x, y);
		
		foreach(obj; Refs)
		{
			if((obj.Position - pos).LengthSq() < 0.1)
				return cast(int)obj.Height.Value;
		}
		
		return 0;
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
