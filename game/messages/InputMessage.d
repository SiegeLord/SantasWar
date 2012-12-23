module game.messages.InputMessage;

import game.IMessage;
import tango.io.stream.Data;

enum EInput
{
	Up,
	Left,
	Right,
	Down,
	Launch,
	Respawn,
	Collect
}

class CInputMessage : IMessage
{
	this(EInput input = EInput.init)
	{
		Input = input;
	}
	
	override
	void Read(DataInput data)
	{
		Input = cast(EInput)data.int32();
		Down = data.int8() != 0;
	}

	override
	void Write(DataOutput data)
	{
		data.int32(cast(int)Input);
		data.int8(Down ? 1 : 0);
	}
	
	@property
	EMessageType Type()
	{
		return EMessageType.Input;
	}

	EInput Input;
	bool Down;
}
