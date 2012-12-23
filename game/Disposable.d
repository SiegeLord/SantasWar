module game.Disposable;

version(DebugDisposable) import tango.stdc.stdio;

/**
 * A simple class that formalizes the non-managed resource management. The advantage of using this
 * is that with version DebugDisposable defined, it will track whether all the resources were disposed of
 */
class CDisposable
{
	this()
	{
		version(DebugDisposable)
		{
			InstanceCounts[this.classinfo.name]++;
		}
		
		IsDisposed = false;
	}
	
	void Dispose()
	{
		version(DebugDisposable)
		{
			if(!IsDisposed)
			{
				InstanceCounts[this.classinfo.name]--;
			}
		}

		IsDisposed = true;
	}
	
protected:
	bool IsDisposed = false;
}

version(DebugDisposable)
{
	size_t[char[]] InstanceCounts;

	static ~this()
	{
		printf("Disposable classes instance counts:\n");
		bool any = false;
		foreach(name, num; InstanceCounts)
		{
			if(num)
			{
				printf("%s: \033[1;31m%d\033[0m\n", (name ~ "\0").ptr, num);
				any = true;
			}
		}
		if(!any)
			printf("No leaked instances!\n");
	}
}
