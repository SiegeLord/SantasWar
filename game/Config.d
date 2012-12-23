module game.Config;

import game.Disposable;

import slconfig;

class CConfig : CDisposable
{
	this()
	{
		Node = SNode();
	}
	this(SNode node)
	{
		Node = node;
	}
	
	override
	void Dispose()
	{
		super.Dispose();
		node.Destroy();
	}
	
	alias Node this;
	SNode Node;
}
