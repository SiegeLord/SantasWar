module game.systems.AmmoSystem;

import game.System;
import game.IGame;
import game.ISimulation;
import game.GameObject;
import game.MathTypes;

import game.components.Bool;
import game.components.Vector;
import game.components.Float;
import game.components.Direction;
import game.components.AnimationSet;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;
import tango.math.Math;

class CAmmoSystem : CSystem
{
	this(IGame game)
	{
		Game = game;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CBool WantCollect;
		CFloat NextCollectTime;
		CFloat NextMoveTime;
		CFloat NextLaunchTime;
		CFloat CollectInterval;
		CFloat Charge;
		CFloat Ammo;
		CAnimationSet Animation;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CBool want_collect;
		CFloat next_collect_time;
		CFloat next_move_time;
		CFloat next_launch_time;
		CFloat collect_interval;
		CFloat charge;
		CFloat ammo;
		CAnimationSet animation;

		if(object.Get("want_collect", want_collect) &&
		   object.Get("charge", charge) &&
		   object.Get("ammo", ammo) &&
		   object.Get("next_launch_time", next_launch_time) &&
		   object.Get("next_move_time", next_move_time) &&
		   object.Get("next_collect_time", next_collect_time) &&
		   object.Get("animation", animation) &&
		   object.Get("collect_interval", collect_interval))
		{
			Refs ~= SObject(object, want_collect, next_collect_time, next_move_time,
			    next_launch_time, collect_interval, charge, ammo, animation);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
	
	override
	void Logic(float dt)
	{
		foreach(obj; Refs)
		{
			if(obj.WantCollect.Value > 0 && Game.Time > obj.NextCollectTime.Value && obj.Charge.Value < 0.001 && obj.Ammo.Value < 6)
			{
				obj.Ammo.Value += 1;
				obj.NextLaunchTime.Value = Game.Time + obj.CollectInterval.Value;
				obj.NextMoveTime.Value = Game.Time + obj.CollectInterval.Value;
				obj.NextCollectTime.Value = Game.Time + obj.CollectInterval.Value;
				obj.Animation.SetState(EAnimationState.Collect);
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
