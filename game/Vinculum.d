module game.Vinculum;

import game.Channel;
import game.Util;
import game.IMessage;

class CVinculum
{
	this()
	{
		ClientChannelVal = new CVinculumChannel;
		ServerChannelVal = new CVinculumChannel;
		
		ClientChannelVal.ReceivingChannel = ServerChannel;
		ServerChannelVal.ReceivingChannel = ClientChannel;
	}
	
	class CVinculumChannel : CChannel
	{
		override
		void Send(IMessage message)
		{
			ReceivingChannel.ReceiveEvent.Trigger(message);
		}
	protected:
		CChannel ReceivingChannel;
	}
	
	@property
	CChannel ClientChannel()
	{
		return ClientChannelVal;
	}
	
	@property
	CChannel ServerChannel()
	{
		return ServerChannelVal;
	}
protected:
	CVinculumChannel ClientChannelVal;
	CVinculumChannel ServerChannelVal;
}
