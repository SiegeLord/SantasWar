module game.Mode;

import game.Disposable;
import game.Util;

import game.IGame;

import allegro5.allegro;

class CMode : CDisposable
{
	this(IGame game)
	{
		Game = game;
	}
	
	override
	void Dispose()
	{
		super.Dispose;
	}
	
	abstract EMode Logic(float dt);
	abstract void Draw();
	abstract EMode Input(ALLEGRO_EVENT* event);
	mixin(Prop!("IGame", "Game", "", "protected"));
protected:
	IGame GameVal;
}
