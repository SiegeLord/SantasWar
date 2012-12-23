module game.Main;

import game.Game;
import allegro5.allegro;

void main(char[][] args)
{
	al_run_allegro(
	{
		auto game = new CGame();
		scope(exit) game.Dispose();
		game.Run();
		
		return 0;
	});
}
