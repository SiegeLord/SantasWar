module game.messages.TestMessage;

import game.IMessage;
import tango.io.stream.Data;

class CTestMessage : IMessage
{
	override
	void Read(DataInput data)
	{
		Message = cast(char[])data.array();
	}

	override
	void Write(DataOutput data)
	{
		data.array(Message);
	}
	
	@property
	EMessageType Type()
	{
		return EMessageType.Test;
	}
protected:
	const(char)[] Message;
}
