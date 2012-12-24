module game.Main;

import game.Game;
import allegro5.allegro;

void main(char[][] args)
{
	al_run_allegro(
	{
		bool dedicated = false;
		if(args.length > 1 && args[1] == "dedicated")
			dedicated = true;
		auto game = new CGame(dedicated);
		scope(exit) game.Dispose();
		game.Run();
		
		return 0;
	});
}
