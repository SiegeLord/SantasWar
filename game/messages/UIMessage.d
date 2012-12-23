module game.messages.UIMessage;

import game.IMessage;
import game.IGame;
import tango.io.stream.Data;

class CUIMessage : IMessage
{
	override
	void Read(DataInput data)
	{
		Health = data.int32();
		RedScore = data.int32();
		BlueScore = data.int32();
		Ammo = data.int32();
		Resolution = cast(EGameResolution)data.int32();
		MatchTime = data.float32();
	}

	override
	void Write(DataOutput data)
	{
		data.int32(Health);
		data.int32(RedScore);
		data.int32(BlueScore);
		data.int32(Ammo);
		data.int32(cast(int)Resolution);
		data.float32(MatchTime);
	}
	
	@property
	EMessageType Type()
	{
		return EMessageType.UI;
	}

	int Health;
	int RedScore;
	int BlueScore;
	int Ammo;
	float MatchTime;
	EGameResolution Resolution;
}
