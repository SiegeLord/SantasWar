module game.systems.LauncherSystem;

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

class CLauncherSystem : CSystem
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
		CDirection Direction;
		CFloat NextLaunchTime;
		CFloat LaunchInterval;
		CFloat NextMoveTime;
		CFloat NextCollectTime;
		CFloat Charge;
		CBool WantCharge;
		CFloat Ammo;
		CAnimationSet Animation;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector position;
		CVector old_position;
		CBool want_launch;
		CBool want_charge;
		CDirection direction;
		CFloat next_launch_time;
		CFloat next_move_time;
		CFloat next_collect_time;
		CFloat launch_interval;
		CFloat charge;
		CFloat ammo;
		CAnimationSet animation;

		if(object.Get("position", position) &&
		   object.Get("direction", direction) &&
		   object.Get("want_charge", want_charge) &&
		   object.Get("charge", charge) &&
		   object.Get("ammo", ammo) &&
		   object.Get("next_launch_time", next_launch_time) &&
		   object.Get("next_move_time", next_move_time) &&
		   object.Get("next_collect_time", next_collect_time) &&
		   object.Get("animation", animation) &&
		   object.Get("launch_interval", launch_interval))
		{
			Refs ~= SObject(object, position, direction, next_launch_time, 
			    launch_interval, next_move_time, next_collect_time, charge, want_charge, ammo, animation);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
	
	override
	void Logic(float dt)
	{
		foreach(obj; Refs)
		{
			if(obj.WantCharge.Value && (obj.Charge.Value > 0 || Game.Time > obj.NextLaunchTime.Value) && obj.Ammo.Value > 0.1)
			{
				obj.Charge.Value += dt;
				if(Game.Time > obj.NextLaunchTime.Value)
					obj.Animation.SetState(EAnimationState.Charge);
				else
					obj.Animation.SetState(EAnimationState.ChargeMove);
			}
			
			if(!obj.WantCharge.Value && obj.Charge.Value > 0 && Game.Time > obj.NextLaunchTime.Value)
			{
				if(obj.Ammo.Value > 0.1)
				{
					obj.Ammo.Value -= 1.0;
					
					auto snowball = Simulation.AddObject("objects/snowball.cfg");
					CVector position;
					CDirection direction;
					CFloat power;
					CFloat vertical_velocity;
					
					SVector2D dir;
					final switch(obj.Direction.Value)
					{
						case EDirection.Up:
							dir.Set(0, -0.6);
							break;
						case EDirection.Down:
							dir.Set(0, 0.6);
							break;
						case EDirection.Left:
							dir.Set(-0.6, 0);
							break;
						case EDirection.Right:
							dir.Set(0.6, 0);
							break;
					}
					
					dir += SVector2D(0.5, 0.5);
					
					if(snowball.Get("position", position) && snowball.Get("direction", direction) && snowball.Get("power", power) && snowball.Get("vertical_velocity", vertical_velocity))
					{
						position.Value = obj.Position.Value + dir;
						direction.Value = obj.Direction.Value;
						power.Value = min(obj.Charge.Value, 4);
						vertical_velocity.Value = power.Value;
					}
					
					obj.NextLaunchTime.Value = Game.Time + obj.LaunchInterval.Value;
					obj.NextMoveTime.Value = Game.Time + obj.LaunchInterval.Value;
					obj.NextCollectTime.Value = Game.Time + obj.LaunchInterval.Value;
					obj.Charge.Value = 0;
					obj.Animation.SetState(EAnimationState.Launch);
				}
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
	ISimulation Simulation;
	IGame Game;
	SObject[] Refs;
}
