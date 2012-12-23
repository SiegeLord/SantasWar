module game.components.AnimationSet;

import game.MathTypes;
import game.Component;
import game.Sprite;
import game.IGame;
import game.components.Direction;

import tango.io.stream.Data;
import tango.text.convert.Format;

enum EAnimationState : int
{
	Stand,
	Move,
	Charge,
	ChargeMove,
	Launch,
	Collect,
	NumStates
}

class CAnimationSet : CComponent
{
	this(const(char)[] name, const(char)[] value, bool need_sync)
	{
		super(name, need_sync);
		Filename = value;
	}
	
	override
	void SaveState(DataOutput data)
	{
		data.int32(cast(int)State);
	}
	
	override
	void LoadState(DataInput data)
	{
		State = cast(EAnimationState)data.int32();
	}
	
	void Load(IGame game)
	{
		if(Loaded)
			return;
		
		auto cfg = game.ConfigManager.Load(Filename);
		
		foreach(state; EAnimationState.Stand..EAnimationState.NumStates)
		{
			const(char)[] state_str = ["stand", "move", "charge", "charge_move", "launch", "collect"][state];
			
			foreach(dir; 0..4)
			{
				const(char)[] dir_str = ["up", "down", "left", "right"][dir];
				
				Sprites[state][dir] = new CSprite(cfg[Format("{}_{}", state_str, dir_str)].GetValue!(const(char)[])(""), game.ConfigManager, game.BitmapManager);
			}
		}
		
		Loaded = true;
	}
	
	CSprite GetSprite(float time, EDirection dir)
	{
		if(!Loaded)
			return null;
		
		if(OldState != State && !(OldState == EAnimationState.ChargeMove && State == EAnimationState.Charge))
		{
			foreach(ii; 0..4)
			{
				Sprites[State][ii].TimeOffset = time;
				OldState = State;
			}
		}	
			
		return Sprites[State][dir];
	}
	
	void SetState(EAnimationState state)
	{
		State = state;
	}
	
	EAnimationState State = EAnimationState.Stand;
	EAnimationState OldState = EAnimationState.Stand;
	const(char)[] Filename;
	bool Loaded = false;
	CSprite[4][EAnimationState.NumStates] Sprites;
}
