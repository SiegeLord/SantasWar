module game.messages.MapInitMessage;

import game.IMessage;
import tango.io.stream.Data;

class CMapInitMessage : IMessage
{
	override
	void Read(DataInput data)
	{
		Width = data.int32();
		Height = data.int32();
		TileMap = cast(uint[])data.array();
	}

	override
	void Write(DataOutput data)
	{
		data.int32(Width);
		data.int32(Height);
		data.array(TileMap);
	}
	
	@property
	EMessageType Type()
	{
		return EMessageType.MapInit;
	}

	int Width;
	int Height;
	uint[] TileMap;
}
