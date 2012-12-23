module game.components.Explosion;

import game.MathTypes;
import game.Component;
import game.Sprite;
import game.IGame;
import game.components.Direction;

import tango.io.stream.Data;
import tango.text.convert.Format;

class CExplosion : CComponent
{
	this(const(char)[] name, const(char)[] value, bool need_sync)
	{
		super(name, need_sync);
		Filename = value;
	}
	
	void Load(IGame game)
	{
		if(Loaded)
			return;
		
		Sprite = new CSprite(Filename, game.ConfigManager, game.BitmapManager);
		
		Loaded = true;
	}
	

	const(char)[] Filename;
	bool Loaded = false;
	CSprite Sprite;
}
