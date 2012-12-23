module game.Component;

import game.Util;

import tango.io.stream.Data;

class CComponent
{
	this(const(char)[] name, bool need_sync)
	{
		Name = name;
		NeedSync = need_sync;
	}
	
	void SaveState(DataOutput data)
	{
		
	}
	
	void LoadState(DataInput data)
	{
		
	}
	
	mixin(Prop!("const(char)[]", "Name", "", "protected"));
	mixin(Prop!("bool", "NeedSync", "", "protected"));
protected:
	const(char)[] NameVal;
	bool NeedSyncVal;
}
