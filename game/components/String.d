module game.components.String;

import game.MathTypes;
import game.Component;

import tango.io.stream.Data;

class CString : CComponent
{
	this(const(char)[] name, const(char)[] value, bool need_sync)
	{
		super(name, need_sync);
		Value = value;
	}
	
	override
	void SaveState(DataOutput data)
	{
		data.array(Value);
	}
	
	override
	void LoadState(DataInput data)
	{
		Value = cast(char[])data.array();
	}
	
	const(char)[] Value;
	
	alias Value this;
}
