module game.IMessage;

import tango.io.stream.Data;

enum EMessageType
{
	Test,
	Input,
	State,
	Name,
	MapInit,
	UI
}

interface IMessage
{
	void Read(DataInput data);
	void Write(DataOutput data);
	@property
	EMessageType Type();
}
