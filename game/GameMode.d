module game.GameMode;

import game.Util;
import game.Mode;
import game.IGame;
import game.Server;
import game.Host;
import game.Vinculum;
import game.Client;
import game.Font;

import allegro5.allegro;
import allegro5.allegro_font;
import allegro5.d_util;

import tango.io.Stdout;
import tango.text.convert.Format;

class CGameMode : CMode
{
	this(IGame game)
	{
		super(game);
		
		Font = game.FontManager.Load("fonts/8bitoperator_jve.ttf", -16);
		
		final switch(Game.GameType)
		{
			case EGameType.Single:
				SingleGame();
				break;
			case EGameType.Join:
				ClientGame(Game.HostName);
				break;
			case EGameType.Host:
				ServerGame();
				break;
		}
	}
	
	override
	void Dispose()
	{
		super.Dispose;
		if(Client !is null)
			Client.Dispose();
		if(Server !is null)
			Server.Dispose();
		if(Host !is null)
			Host.Dispose();
	}
	
	override
	EMode Logic(float dt)
	{
		if(Client !is null)
			Client.Logic(dt);
		if(Server !is null)
			Server.Logic(dt);
		if(Host !is null)
			Host.Logic(dt);
			
		if(Exit)
			return ExitCompletely ? EMode.Exit : EMode.Menu;
		else
			return EMode.Game;
	}
	
	override
	void Draw()
	{
		al_clear_to_color(al_map_rgb_f(0, 0, 0));
		if(Host is null && Game.GameType != EGameType.Single)
		{
			al_draw_text(Font.Get, al_map_rgb_f(1, 1, 1), Game.Gfx.ScreenWidth / 2, Game.Gfx.ScreenHeight / 2, ALLEGRO_ALIGN_CENTRE, "Failed to create host!");
		}
		if(Client is null && Host !is null)
		{
			ALLEGRO_USTR_INFO info;
			al_draw_ustr(Font.Get, al_map_rgb_f(1, 1, 1), Game.Gfx.ScreenWidth / 2, Game.Gfx.ScreenHeight / 2, ALLEGRO_ALIGN_CENTRE, dstr_to_ustr(&info, Format(`Connecting to "{}"...`, Game.HostName)));
		}
		else if(Client !is null)
		{
			Client.Draw();
		}
	}
	
	override
	EMode Input(ALLEGRO_EVENT* event)
	{
		if(Client !is null)
			Client.Input(event);
		
		void handle_close()
		{
			if(Host is null || Host.NumPeers == 0)
			{
				Exit = true;
			}
			else
			{
				Host.Disconnect();
				WantExit = true;
			}
		}
		
		switch(event.type)
		{
			case ALLEGRO_EVENT_DISPLAY_CLOSE:
				ExitCompletely = true;
				handle_close();
				break;
			case ALLEGRO_EVENT_KEY_DOWN:
				if(event.keyboard.keycode == ALLEGRO_KEY_ESCAPE)
				{
					ExitCompletely = false;
					handle_close();
				}
				break;	
			default:
		}
		
		return EMode.Game;
	}
	
	void SingleGame()
	{
		Vinculum = new CVinculum;
		Client = new CClient(Game, Vinculum.ClientChannel);
		Server = new CServer(Game);
		Server.AddPlayer(Vinculum.ServerChannel);
	}
	
	void ClientGame(const(char)[] hostname)
	{
		Host = new CHost();
		if(Host.Valid)
		{
			Host.ConnectionEvent.Register((channel) { Client = new CClient(Game, channel); });
			Host.AllDisconnectedEvent.Register({ Exit = true; });
			Host.Connect(hostname, Game.Port);
		}
		else
		{
			Host.Dispose();
			Host = null;
		}
	}
	
	void ServerGame()
	{
		Host = new CHost(Game.Port);
		if(Host.Valid)
		{
			Host.ConnectionEvent.Register((channel) { Server.AddPlayer(channel); });
			Host.DisconnectionEvent.Register((channel) { Server.RemovePlayer(channel); });
			Host.AllDisconnectedEvent.Register({ if(WantExit) Exit = true; });
		}
		else
		{
			Host.Dispose();
			Host = null;
			return;
		}
		
		Vinculum = new CVinculum;
		Client = new CClient(Game, Vinculum.ClientChannel);
		Server = new CServer(Game);
		Server.AddPlayer(Vinculum.ServerChannel);
	}
protected:
	bool ExitCompletely = false;
	bool WantExit = false;
	bool Exit = false;
	CVinculum Vinculum;
	CServer Server;
	CClient Client;
	CHost Host;
	CFont Font;
}
