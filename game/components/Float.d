module game.components.Float;

import game.MathTypes;
import game.Component;

import tango.io.stream.Data;
import tango.util.Convert;

class CFloat : CComponent
{
	this(const(char)[] name, const(char)[] value, bool need_sync)
	{
		super(name, need_sync);
		if(value != "")
			Value = to!(float)(value);
		else
			Value = 0.0f;
	}
	
	override
	void SaveState(DataOutput data)
	{
		data.float32(Value);
	}
	
	override
	void LoadState(DataInput data)
	{
		Value = data.float32();
	}
	
	float Value;
	
	alias Value this;
}
