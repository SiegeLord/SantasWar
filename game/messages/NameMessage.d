module game.messages.NameMessage;

import game.IMessage;
import tango.io.stream.Data;

class CNameMessage : IMessage
{
	override
	void Read(DataInput data)
	{
		Name = cast(char[])data.array();
	}

	override
	void Write(DataOutput data)
	{
		data.array(Name);
	}
	
	@property
	EMessageType Type()
	{
		return EMessageType.Name;
	}

	const(char)[] Name;
}
