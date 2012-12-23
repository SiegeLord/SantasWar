module game.messages.StateMessage;

import game.IMessage;
import tango.io.stream.Data;
import tango.io.device.Array;
import tango.io.Stdout;

class CStateMessage : IMessage
{
	this()
	{
		StateArray = new Array(128, 1024);
	}
	
	override
	void Read(DataInput data)
	{
		auto arr = data.array();
		StateArray.write(arr);
	}

	override
	void Write(DataOutput data)
	{
		StateArray.seek(0);
		data.array(StateArray.slice());
	}
	
	@property
	EMessageType Type()
	{
		return EMessageType.State;
	}

	Array StateArray;
}
