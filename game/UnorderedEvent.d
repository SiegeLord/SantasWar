module game.UnorderedEvent;

import tango.core.Array;

final class CUnorderedEvent(TArgs...)
{
	alias void delegate(TArgs) TDelegate;
	
	void Register(TDelegate dg)
	{
		Delegates ~= dg;
	}
	
	void UnRegister(TDelegate dg)
	{
		auto new_len = Delegates.partition((TDelegate a) => dg !is a);
		Delegates.length = new_len;
	}
	
	void Trigger(TArgs args)
	{
		foreach(dg; Delegates)
			dg(args);
	}
	
protected:
	TDelegate[] Delegates;
} 

version(UnitTest)
{
	unittest
	{
		auto event = new CUnorderedEvent!(int);
		
		int a_vals = 0;
		int b_vals = 0;
		
		void delegate(int) dg = (int v) { a_vals += v; };
		
		event.Register(dg);
		event.Register((v) {b_vals += v;});
		event.Trigger(5);
		assert(a_vals == 5);
		assert(b_vals == 5);
		event.UnRegister(dg);
		event.Trigger(5);
		assert(a_vals == 5);
		assert(b_vals == 10);
	}
}
