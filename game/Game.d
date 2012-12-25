module game.Game;

import core.memory;

import game.BitmapManager;
import game.ConfigManager;
import game.FontManager;
import game.Gfx;
import game.Disposable;
import game.Util;
import game.Config;
import game.IGame;
import game.Mode;
import game.GameMode;
import game.MenuMode;
import game.DedicatedMode;
import game.TileSheet;

import enet.enet;

import tango.io.Stdout;
import tango.io.device.File;
import tango.text.convert.Format;

import allegro5.allegro;
import allegro5.allegro_image;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

import slconfig;

class CGame : CDisposable, IGame
{
	this(bool dedicated)
	{
		Dedicated = dedicated;
		
		al_init();
		if(!Dedicated)
		{
			al_install_keyboard();
			al_install_mouse();
		}
		al_init_font_addon();
		al_init_ttf_addon();
		al_init_image_addon();
		
		BitmapManager = new CBitmapManager;
		FontManager = new CFontManager;
		ConfigManager = new CConfigManager;
		Options = ConfigManager.Load("options.cfg");
		if(!Dedicated)
			Gfx = new CGfx(Options);
		TileSheet = new CTileSheet("tilesheets/tilesheet.cfg", ConfigManager, BitmapManager);
		
		PlayerName = Options.player_name.GetValue!(const(char)[])("");
		HostName = Options.hostname.GetValue!(const(char)[])("");
		Port = Options.port.GetValue!(ushort)(1024);
		MatchDuration = Options.match_duration.GetValue!(int)(5);
		
		Queue = al_create_event_queue();
		if(!Dedicated)
		{
			al_register_event_source(Queue, al_get_keyboard_event_source());
			al_register_event_source(Queue, al_get_mouse_event_source());
			al_register_event_source(Queue, al_get_display_event_source(Gfx.Display));
		}
		
		if(enet_initialize() != 0)
		{
			Stderr("Failed to initialize enet.").nl;
			assert(0);
		}
	}
	
	override
	void Dispose()
	{
		super.Dispose;
		
		if(!Options.Node.Valid)
			Options.Node = SNode();
		
		if(!Options["player_name"].Valid)
			Options.AddNode("", "player_name", false);
		if(!Options["hostname"].Valid)
			Options.AddNode("", "hostname", false);
		if(!Options["port"].Valid)
			Options.AddNode("", "port", false);
		if(!Options["match_duration"].Valid)
			Options.AddNode("", "match_duration", false);

		Options["player_name"] = PlayerName;
		Options["hostname"] = HostName;
		Options["port"] = Port;
		Options["match_duration"] = MatchDuration;
		
		auto file = new File("options.cfg", File.WriteCreate);
		file.write(Options.Node.toString());
		scope(exit) file.close();
		
		al_destroy_event_queue(Queue);
		
		if(!Dedicated)
			Gfx.Dispose;
		ConfigManager.Dispose;
		FontManager.Dispose;
		BitmapManager.Dispose;
		
		Options.Destroy();
		
		enet_deinitialize();
	}
	
	void Run()
	{
		CMode mode;
		EMode next_mode = Dedicated ? EMode.Dedicated : EMode.Menu;
		while(true)
		{
			scope(exit)
				if(mode) mode.Dispose;
			final switch(next_mode)
			{
				case EMode.Dedicated:
					mode = new CDedicatedMode(this);
					break;
				case EMode.Game:
					mode = new CGameMode(this);
					break;
				case EMode.Menu:
					mode = new CMenuMode(this);
					break;
				case EMode.Exit:
					mode = null;
					goto exit;
			}
			next_mode = GameLoop(mode, next_mode);
		}
exit:{}
	}

	mixin(Prop!("double", "Time", "override", "protected"));
	mixin(Prop!("CGfx", "Gfx", "override", "protected"));
	mixin(Prop!("CConfig", "Options", "override", "protected"));
	mixin(Prop!("CConfigManager", "ConfigManager", "override", "protected"));
	mixin(Prop!("CBitmapManager", "BitmapManager", "override", "protected"));
	mixin(Prop!("CFontManager", "FontManager", "override", "protected"));
	mixin(Prop!("CTileSheet", "TileSheet", "override", "protected"));
	mixin(Prop!("const(char)[]", "PlayerName", "override", "override"));
	mixin(Prop!("const(char)[]", "HostName", "override", "override"));
	mixin(Prop!("EGameType", "GameType", "override", "override"));
	mixin(Prop!("ushort", "Port", "override", "protected"));
	mixin(Prop!("int", "MatchDuration", "override", "override"));
	mixin(Prop!("const(char)[]", "Map", "override", "override"));
protected:
	EMode GameLoop(CMode mode, EMode old_mode)
	{
		ALLEGRO_EVENT event;
		Time = 0;
		
		float cur_time = al_get_time();
		float accumulator = 0;
		//float physics_alpha = 0;
		
		while(1)
		{
			float new_time = al_get_time();
			float delta_time = new_time - cur_time;
			al_rest(FixedDt - delta_time);
			
			delta_time = new_time - cur_time;
			cur_time = new_time;

			accumulator += delta_time;

			while (accumulator >= FixedDt)
			{
				while(al_get_next_event(Queue, &event))
				{
					auto new_mode = mode.Input(&event);
					if(new_mode != old_mode)
						return new_mode;
				}
				
				auto new_mode = mode.Logic(FixedDt);
				if(new_mode != old_mode)
					return new_mode;
				
				Time = Time + FixedDt;
				accumulator -= FixedDt;
			}

			//physics_alpha = accumulator / FixedDt;
			
			if(!Dedicated)
			{
				mode.Draw();
				Gfx.FlipDisplay();
			}
		}
		assert(0);
	}

	ALLEGRO_EVENT_QUEUE* Queue;
	double TimeVal = 0.0f;
	
	CTileSheet TileSheetVal;
	CBitmapManager BitmapManagerVal;
	CConfigManager ConfigManagerVal;
	CFontManager FontManagerVal;
	CConfig OptionsVal;
	const(char)[] PlayerNameVal;
	const(char)[] HostNameVal;
	CGfx GfxVal;
	bool LoadVal = false;
	EGameType GameTypeVal;
	ushort PortVal;
	int MatchDurationVal;
	const(char)[] MapVal;
	
	bool Dedicated;
}
