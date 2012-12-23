module game.Channel;

import game.IMessage;
import game.UnorderedEvent;

class CChannel
{
	this()
	{
		ReceiveEvent = new typeof(ReceiveEvent)();
	}
	
	abstract void Send(IMessage message);	
	CUnorderedEvent!(IMessage) ReceiveEvent;
}
