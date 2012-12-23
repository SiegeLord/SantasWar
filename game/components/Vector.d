module game.components.Vector;

import game.MathTypes;
import game.Component;

import tango.io.stream.Data;

class CVector : CComponent
{
	this(const(char)[] name, const(char)[] value, bool need_sync)
	{
		super(name, need_sync);
	}
	
	override
	void SaveState(DataOutput data)
	{
		data.float32(Value.X);
		data.float32(Value.Y);
	}
	
	override
	void LoadState(DataInput data)
	{
		Value.X = data.float32();
		Value.Y = data.float32();
	}
	
	SVector2D Value;
	
	alias Value this;
}
