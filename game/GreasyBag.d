module game.GreasyBag;

import tango.core.Array;

class CGreasyBag(TElem)
{
	this(bool preserve_order = false)
	{
		PreserveOrder = preserve_order;
	}
	
	CElemHolder Add(TElem elem)
	{
		auto holder = new CElemHolder(elem);
		Holders ~= holder;
		return holder;
	}
	
	void RemoveLater(CElemHolder holder)
	{
		if(!holder.RemoveMe)
			NumToRemove++;
		holder.RemoveMe = true;
	}
	
	void Prune()
	{
		if(NumToRemove)
		{
			size_t new_size;
			if(PreserveOrder)
				new_size = Holders.removeIf((CElemHolder holder) => holder.RemoveMe);
			else
				new_size = Holders.partition((CElemHolder holder) => !holder.RemoveMe);
			Holders.length = new_size;
			NumToRemove = 0;
		}
	}
	
	int opApply(scope int delegate(ref TElem elem) dg)
	{
		int ret = 0;
		foreach(holder; Holders)
		{
			if(!holder.RemoveMe)
			{
				if((ret = dg(holder.Elem)) != 0)
					break;
			}
		}
		return ret;
	}
	
	@property
	size_t length()
	{
		return Holders.length - NumToRemove;
	}
	
	class CElemHolder
	{
		this(TElem elem)
		{
			Elem = elem;
		}
	private:
		TElem Elem;
		bool RemoveMe = false;
	}
protected:
	size_t NumToRemove = 0;
	CElemHolder[] Holders;
	bool PreserveOrder = false;
}

unittest
{
	{
		auto bag = new CGreasyBag!(int)();
		auto holder = bag.Add(5);
		assert(bag.length == 1);
		
		bool tried_it = false;
		foreach(int elem; bag)
		{
			tried_it = true;
			assert(elem == 5);
		}
		assert(tried_it);
		
		bag.RemoveLater(holder);
		assert(bag.length == 0);
		
		tried_it = false;
		foreach(int elem; bag)
		{
			tried_it = true;
		}
		assert(!tried_it);
		
		bag.Prune();
		assert(bag.Holders.length == 0);
	}
	
	{
		auto bag = new CGreasyBag!(int)(true);
		auto holder = bag.Add(1);
		bag.Add(2);
		bag.Add(3);
		bag.RemoveLater(holder);
		bag.Prune();
		
		int[] elems;
		foreach(elem; bag)
		{
			elems ~= elem;
		}
		assert(elems == [2, 3]);
	}
}
