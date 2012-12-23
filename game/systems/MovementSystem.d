module game.systems.MovementSystem;

import game.System;
import game.IGame;
import game.GameObject;
import game.ISimulation;

import game.components.Bool;
import game.components.Vector;
import game.components.Float;
import game.components.Direction;
import game.components.AnimationSet;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.core.Array;
import tango.io.Stdout;

class CMovementSystem : CSystem
{
	this(IGame game, ISimulation sim)
	{
		Game = game;
		Simulation = sim;
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector OldPosition;
		CVector Position;
		CFloat MoveInterval;
		CFloat NextMoveTime;
		CFloat NextLaunchTime;
		CFloat NextCollectTime;
		CDirection Direction;
		CDirection DesiredDirection;
		CBool WantMove;
		CFloat Charge;
		CAnimationSet Animation;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector old_position;
		CVector position;
		CFloat move_interval;
		CFloat next_move_time;
		CFloat next_launch_time;
		CFloat next_collect_time;
		CFloat charge;
		CDirection direction;
		CDirection desired_direction;
		CBool want_move;
		CAnimationSet animation;

		if(object.Get("old_position", old_position) &&
		   object.Get("position", position) &&
		   object.Get("move_interval", move_interval) &&
		   object.Get("next_move_time", next_move_time) &&
		   object.Get("next_launch_time", next_launch_time) &&
		   object.Get("next_collect_time", next_collect_time) &&
		   object.Get("direction", direction) &&
		   object.Get("charge", charge) &&
		   object.Get("desired_direction", desired_direction) &&
		   object.Get("animation", animation) &&
		   object.Get("want_move", want_move))
		{
			Refs ~= SObject(object, old_position, position, move_interval, next_move_time, next_launch_time, next_collect_time, direction, desired_direction, want_move, charge, animation);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
	
	override
	void Logic(float dt)
	{
		foreach(obj; Refs)
		{
			bool can_move = false;
			if((obj.OldPosition.Value - obj.Position.Value).LengthSq > 0.1)
			{
				if(Game.Time > obj.NextMoveTime.Value)
				{
					obj.OldPosition.Value = obj.Position.Value;
					can_move = true;
				}
			}
			else
			{
				can_move = true;
			}

			if(can_move && Game.Time > obj.NextMoveTime.Value)
			{
				if(obj.WantMove.Value)
				{
					if(obj.Charge.Value < 0.01)
					{
						obj.Direction.Value = obj.DesiredDirection.Value;
						obj.Animation.SetState(EAnimationState.Move);
					}
					else
					{
						obj.Animation.SetState(EAnimationState.Move);
					}
					
					auto new_pos = obj.Position.Value;
					
					final switch(obj.DesiredDirection.Value)
					{
						case EDirection.Up:
							new_pos.Y -= 1;
							break;
						case EDirection.Down:
							new_pos.Y += 1;
							break;
						case EDirection.Right:
							new_pos.X += 1;
							break;
						case EDirection.Left:
							new_pos.X -= 1;
							break;
					}
					
					if(Simulation.GetHeight(cast(int)new_pos.X, cast(int)new_pos.Y) == 0)
					{
						obj.Position.Value = new_pos;
						obj.NextMoveTime.Value = Game.Time + obj.MoveInterval.Value;
						obj.NextLaunchTime.Value = Game.Time + obj.MoveInterval.Value;
						obj.NextCollectTime.Value = Game.Time + obj.MoveInterval.Value;
					}
				}
				else if(obj.Charge.Value < 0.01)
				{
					obj.Animation.SetState(EAnimationState.Stand);
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
