module game.DedicatedMode;

import game.Util;
import game.Mode;
import game.IGame;
import game.Server;
import game.Host;
import game.MapList;

import allegro5.allegro;

import tango.io.Stdout;
import tango.text.convert.Format;

class CDedicatedMode : CMode
{
	this(IGame game)
	{
		super(game);
		
		Reset();
	}
	
	void Reset()
	{
		WantReset = false;
		
		if(Host !is null)
			Host.Dispose();
		
		Host = new CHost(Game.Port);
		if(Host.Valid)
		{
			Host.ConnectionEvent.Register((channel) { Server.AddPlayer(channel); });
			Host.DisconnectionEvent.Register((channel) { Server.RemovePlayer(channel); });
			Host.AllDisconnectedEvent.Register({ WantReset = true; });
		}
		else
		{
			Host.Dispose();
			Host = null;
		}
		
		if(Server !is null)
			Server.Dispose();
		
		scope maps = GetMaps();
		
		if(maps.length == 0)
			throw new Exception("No maps!");
		
		if(MapIdx >= maps.length)
			MapIdx = 0;
		
		Game.Map = maps[MapIdx].File;
		
		MapIdx++;
		
		Server = new CServer(Game);
		Server.MatchEndedEvent.Register({ DisconnectTime = Game.Time + 10; });
	}
	
	override
	void Dispose()
	{
		super.Dispose;
		if(Server !is null)
			Server.Dispose();
	}
	
	override
	EMode Logic(float dt)
	{	
		if(WantReset)
			Reset();
		
		if(Host is null)
			return EMode.Exit;
		
		if(Game.Time > DisconnectTime)
		{
			Host.Disconnect();
			DisconnectTime = double.infinity;
		}
		
		if(Server !is null)
			Server.Logic(dt);
		
		Host.Logic(dt);

		return EMode.Dedicated;
	}
	
	override
	void Draw()
	{
		
	}
	
	override
	EMode Input(ALLEGRO_EVENT* event)
	{
		return EMode.Dedicated;
	}
protected:
	CHost Host;
	CServer Server;
	size_t MapIdx = 0;
	bool WantReset = false;
	double DisconnectTime = double.infinity;
}
