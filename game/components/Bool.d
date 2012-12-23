module game.components.Bool;

import game.MathTypes;
import game.Component;

import tango.util.Convert;
import tango.io.stream.Data;

class CBool : CComponent
{
	this(const(char)[] name, const(char)[] value, bool need_sync)
	{
		super(name, need_sync);
		if(value != "")
			Value = to!(bool)(value);
	}
	
	override
	void SaveState(DataOutput data)
	{
		data.int8(Value ? 1 : 0);
	}
	
	override
	void LoadState(DataInput data)
	{
		Value = data.int8() != 0;
	}
	
	bool Value;
}
