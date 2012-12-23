module game.components.Direction;

import game.MathTypes;
import game.Component;

import tango.io.stream.Data;
import tango.util.Convert;

enum EDirection
{
	Up,
	Down,
	Left,
	Right
}

class CDirection : CComponent
{
	this(const(char)[] name, const(char)[] value, bool need_sync)
	{
		super(name, need_sync);
		Value = EDirection.Down;
	}
	
	override
	void SaveState(DataOutput data)
	{
		data.int32(Value);
	}
	
	override
	void LoadState(DataInput data)
	{
		Value = cast(EDirection)data.int32();
	}
	
	EDirection Value;
	
	alias Value this;
}
