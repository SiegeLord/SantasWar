module game.MenuMode;

import game.Util;
import game.Mode;
import game.Font;
import game.IGame;
import game.Bitmap;
import game.MapList;

import allegro5.allegro;
import allegro5.allegro_font;
import allegro5.d_util;

import tango.io.Stdout;
import tango.math.Math;
import tango.text.convert.Format;
import Utf = tango.text.convert.Utf;

import slconfig;

class CMenuMode : CMode
{
	class CMenuEntry
	{
		this()
		{
			Color = al_map_rgb_f(1, 0.5, 0);
		}
		
		void Input(ALLEGRO_EVENT* event) { }
		void Draw(float x, float y, bool selected)
		{
			ALLEGRO_USTR_INFO info;
			ALLEGRO_COLOR col = selected ? al_map_rgb_f(1, 1, 1) : Color;
			
			al_draw_ustr(Font.Get, col, x, y, ALLEGRO_ALIGN_CENTRE, dstr_to_ustr(&info, Format("{}", Name)));
		}
		
		ALLEGRO_COLOR Flash()
		{
			return Game.Gfx.BlendColors(al_map_rgb_f(1, 1, 1), Color, 0.5 + 0.5 * sin(Game.Time / 0.1));
		}
	
		ALLEGRO_COLOR Color;
		const(char)[] Name;
	}
	
	class CTextEntry : CMenuEntry
	{
		override
		void Input(ALLEGRO_EVENT* event)
		{
			if(event.type == ALLEGRO_EVENT_KEY_CHAR)
			{
				if(event.keyboard.unichar > 32)
				{
					Value ~= Utf.toString((cast(dchar*)&event.keyboard.unichar)[0..1]);
				}
				else if(event.keyboard.keycode == ALLEGRO_KEY_BACKSPACE)
				{
					if(Value.length > 0)
						Value.length--;
				}
			}
		}
		
		override
		void Draw(float x, float y, bool selected)
		{
			ALLEGRO_USTR_INFO info;
			ALLEGRO_COLOR col1 = selected ? al_map_rgb_f(1, 1, 1) : Color;
			ALLEGRO_COLOR col2 = selected ? Flash() : Color;
			
			al_draw_ustr(Font.Get, col1, x - 4, y, ALLEGRO_ALIGN_RIGHT, dstr_to_ustr(&info, Format("{}", Name)));
			al_draw_ustr(Font.Get, col2, x + 4, y, ALLEGRO_ALIGN_LEFT, dstr_to_ustr(&info, Format("{}", Value)));
		}
		
		const(char)[] Value;
	}
	
	class CTimeEntry : CMenuEntry
	{
		override
		void Input(ALLEGRO_EVENT* event)
		{
			if(event.type == ALLEGRO_EVENT_KEY_CHAR)
			{
				if(event.keyboard.keycode == ALLEGRO_KEY_LEFT)
				{
					if(Value > 0)
						Value--;
				}
				else if(event.keyboard.keycode == ALLEGRO_KEY_RIGHT)
				{
					Value++;
				}
			}
		}
		
		override
		void Draw(float x, float y, bool selected)
		{
			ALLEGRO_USTR_INFO info;
			ALLEGRO_COLOR col1 = selected ? al_map_rgb_f(1, 1, 1) : Color;
			ALLEGRO_COLOR col2 = selected ? Flash() : Color;
			
			al_draw_ustr(Font.Get, col1, x - 4, y, ALLEGRO_ALIGN_RIGHT, dstr_to_ustr(&info, Format("{}", Name)));
			al_draw_ustr(Font.Get, col2, x + 4, y, ALLEGRO_ALIGN_LEFT, dstr_to_ustr(&info, Format("{} min", Value)));
		}
		
		int Value;
	}
	
	class CMapEntry : CMenuEntry
	{
		override
		void Input(ALLEGRO_EVENT* event)
		{
			if(event.type == ALLEGRO_EVENT_KEY_CHAR)
			{
				if(event.keyboard.keycode == ALLEGRO_KEY_LEFT)
				{
					MapIdx--;
					if(MapIdx < 0)
						MapIdx = cast(int)Maps.length - 1;
				}
				else if(event.keyboard.keycode == ALLEGRO_KEY_RIGHT)
				{
					MapIdx++;
					if(MapIdx >= cast(int)Maps.length)
						MapIdx = 0;
				}
			}
		}
		
		override
		void Draw(float x, float y, bool selected)
		{
			ALLEGRO_USTR_INFO info;
			ALLEGRO_COLOR col1 = selected ? al_map_rgb_f(1, 1, 1) : Color;
			ALLEGRO_COLOR col2 = selected ? Flash() : Color;
			
			al_draw_ustr(Font.Get, col1, x - 4, y, ALLEGRO_ALIGN_RIGHT, dstr_to_ustr(&info, Format("{}", Name)));
			al_draw_ustr(Font.Get, col2, x + 4, y, ALLEGRO_ALIGN_LEFT, dstr_to_ustr(&info, Format("{}", Maps[MapIdx].Name)));
		}
		
		int MapIdx;
	}
	
	this(IGame game)
	{
		super(game);
		
		Title = Game.BitmapManager.Load("bitmaps/title.png");
		
		Maps = GetMaps();
		
		if(Maps.length == 0)
			throw new Exception("No maps!");
		
		//Font = game.FontManager.Load("fonts/PressStart2P.ttf", -8);
		Font = game.FontManager.Load("fonts/8bitoperator_jve.ttf", -16);
		//Font = game.FontManager.Load("fonts/pzim3x5.ttf", -6);
		
		{
			auto entry = new CMenuEntry;
			entry.Name = "Host Game";
			MenuEntries ~= entry;
		}
		
		{
			auto entry = new CTextEntry;
			entry.Name = "Join Game";
			entry.Value = Game.HostName;
			MenuEntries ~= entry;
			JoinEntry = entry;
		}
		
		{
			auto entry = new CTimeEntry;
			entry.Name = "Match Duration";
			entry.Value = Game.MatchDuration;
			entry.Color = al_map_rgb_f(0.5, 1, 0.5);
			MenuEntries ~= entry;
			MatchEntry = entry;
		}
		
		{
			auto entry = new CMapEntry;
			entry.Name = "Map";
			entry.Color = al_map_rgb_f(0.5, 1, 0.5);
			MenuEntries ~= entry;
			MapEntry = entry;
		}
		
		{
			auto entry = new CTextEntry;
			entry.Name = "Player Name";
			entry.Value = Game.PlayerName;
			entry.Color = al_map_rgb_f(0.5, 1, 0.5);
			MenuEntries ~= entry;
			NameEntry = entry;
		}
		
		{
			auto entry = new CMenuEntry;
			entry.Name = "Exit";
			entry.Color = al_map_rgb_f(1, 0.25, 0.25);
			MenuEntries ~= entry;
		}
	}
	
	override
	EMode Logic(float dt)
	{
		return EMode.Menu;
	}
	
	override
	EMode Input(ALLEGRO_EVENT* event)
	{
		Game.PlayerName = NameEntry.Value;
		Game.HostName = JoinEntry.Value;
		Game.MatchDuration = MatchEntry.Value;
		Game.Map = Maps[MapEntry.MapIdx].File;
		
		MenuEntries[Selection].Input(event);
		
		switch(event.type)
		{
			case ALLEGRO_EVENT_DISPLAY_CLOSE:
				return EMode.Exit;
			case ALLEGRO_EVENT_KEY_DOWN:
				switch(event.keyboard.keycode)
				{
					case ALLEGRO_KEY_UP:
						Selection--;
						if(Selection < 0)
							Selection = cast(int)(MenuEntries.length - 1);
						break;
					case ALLEGRO_KEY_DOWN:
						Selection++;
						if(Selection >= MenuEntries.length)
							Selection = 0;
						break;
					case ALLEGRO_KEY_ENTER:
						switch(Selection)
						{
							case 0:
								Game.GameType = EGameType.Host;
								return EMode.Game;
							case 1:
								Game.GameType = EGameType.Join;
								return EMode.Game;
							case 5:
								return EMode.Exit;
							default: {}
						}
						break;
					default: {}
				}
				break;
			default: {}
		}
		return EMode.Menu;
	}
	
	override
	void Draw()
	{
		al_draw_bitmap(Title.Get, 0, 0, 0);
		
		float spacing = 10;
		float line_height = al_get_font_line_height(Font.Get);
		float total_height = line_height * MenuEntries.length + spacing * (MenuEntries.length - 1);
		
		float x = Game.Gfx.ScreenWidth / 2;
		float y = 2 * Game.Gfx.ScreenHeight / 3 - total_height / 2;
		
		foreach(idx, entry; MenuEntries)
		{
			entry.Draw(x, y, idx == Selection);
			
			y += line_height + spacing;
		}
	}
protected:
	CBitmap Title;
	CTextEntry JoinEntry;
	CTextEntry NameEntry;
	CMapEntry MapEntry;
	CTimeEntry MatchEntry;
	CMenuEntry[] MenuEntries;
	int Selection = 0;
	CFont Font;
	SMap[] Maps;
}
