module game.Client;

import game.Channel;
import game.Disposable;
import game.Simulation;
import game.IMessage;
import game.IGame;
import game.FontManager;
import game.Font;
import game.Bitmap;

import game.messages.TestMessage;
import game.messages.InputMessage;
import game.messages.StateMessage;
import game.messages.NameMessage;
import game.messages.MapInitMessage;
import game.messages.UIMessage;

import allegro5.allegro;
import allegro5.allegro_font;
import allegro5.allegro_primitives;
import allegro5.d_util;

import tango.io.Stdout;
import tango.math.Math;
import tango.io.stream.Data;
import tango.text.convert.Format;

class CClient : CDisposable
{
	this(IGame game, CChannel channel)
	{
		Game = game;
		Simulation = new CSimulation(game, false);
		Snowball = Game.BitmapManager.Load("bitmaps/big_snowball.png");
		Gauge = Game.BitmapManager.Load("bitmaps/gauge.png");
		Channel = channel;
		Channel.ReceiveEvent.Register(&ServerMessage);
		Font = game.FontManager.Load("fonts/8bitoperator_jve.ttf", -16);
	}
	
	void Logic(float dt)
	{
		if(!SentName)
		{
			scope name_message = new CNameMessage;
			name_message.Name = Game.PlayerName.length > 10 ? Game.PlayerName[0..10] : Game.PlayerName;
			Channel.Send(name_message);
			SentName = true;
		}
		Simulation.Logic(dt);
	}
	
	void Draw()
	{
		Simulation.Draw();
		
		if(Health > 0)
		{
			auto x = Game.Gfx.ScreenWidth - 5;
			auto y = Game.Gfx.ScreenHeight - 1;
			//al_draw_filled_rectangle(x, y, x - Health / 2, y - 10, al_map_rgb_f(1, 0, 0));
			al_draw_bitmap_region(Gauge.Get, 0, 0, Health / 2, 16, x - 50, y - 16, 0);
			
			y = Game.Gfx.ScreenHeight - 10;
			
			al_draw_text(Font.Get, al_map_rgb_f(0.5, 0, 0), x - 55, y - al_get_font_line_height(Font.Get) / 2, ALLEGRO_ALIGN_RIGHT, "Willpower: ");
			
			x = 75;
			
			al_draw_text(Font.Get, al_map_rgb_f(0, 0.5, 0.5), 3, y - al_get_font_line_height(Font.Get) / 2, ALLEGRO_ALIGN_LEFT, "Snowballs: ");
			
			y = Game.Gfx.ScreenHeight - 17;
			
			foreach(idx; 0..Ammo)
			{
				//al_draw_filled_circle(x + 15 * idx, y, 5, al_map_rgb_f(0.5, 0.5, 0.5));
				al_draw_bitmap(Snowball.Get, x + 20 * idx, y, 0);
			}
		}
		else
		{
			al_draw_text(Font.Get, Game.Gfx.BlendColors(al_map_rgb_f(0, 0, 0), al_map_rgb_f(1, 1, 0), 0.5 + 0.5 * sin(Game.Time / 0.25)), Game.Gfx.ScreenWidth / 2, Game.Gfx.ScreenHeight / 2, ALLEGRO_ALIGN_CENTRE, "PRESS (R) TO RESPAWN.");
		}
		
		ALLEGRO_USTR_INFO info;
		al_draw_ustr(Font.Get, al_map_rgb_f(1, 0, 0), Game.Gfx.ScreenWidth / 2 - 4, 1, ALLEGRO_ALIGN_RIGHT, dstr_to_ustr(&info, Format("{}", RedScore)));
		al_draw_text(Font.Get, al_map_rgb_f(0, 0, 0), Game.Gfx.ScreenWidth / 2, 1, ALLEGRO_ALIGN_CENTRE, ":");
		al_draw_ustr(Font.Get, al_map_rgb_f(0, 0, 1), Game.Gfx.ScreenWidth / 2 + 4, 1, ALLEGRO_ALIGN_LEFT, dstr_to_ustr(&info, Format("{}", BlueScore)));
		
		if(Resolution == EGameResolution.RedWins)
			al_draw_text(Font.Get, al_map_rgb_f(1, 0, 0), Game.Gfx.ScreenWidth / 2, 16, ALLEGRO_ALIGN_CENTRE, "RED WINS!");
		else if(Resolution == EGameResolution.BlueWins)
			al_draw_text(Font.Get, al_map_rgb_f(0, 0, 1), Game.Gfx.ScreenWidth / 2, 16, ALLEGRO_ALIGN_CENTRE, "BLUE WINS!");
		
		int itime = cast(int)MatchTime;
		int minutes = itime / 60;
		int seconds = itime % 60;
		
		al_draw_ustr(Font.Get, al_map_rgb_f(0, 0, 0.5), Game.Gfx.ScreenWidth - 4, 1, ALLEGRO_ALIGN_RIGHT, dstr_to_ustr(&info, Format("Time Left: {}:{:d2}", minutes, seconds)));
		
		
	}
	
	void ServerMessage(IMessage message)
	{
		switch(message.Type)
		{
			case EMessageType.MapInit:
				auto map_init = cast(CMapInitMessage)message;
				Simulation.CreateMap(map_init.Width, map_init.Height, map_init.TileMap);
				break;
			case EMessageType.UI:
				auto ui = cast(CUIMessage)message;
				Health = ui.Health;
				RedScore = ui.RedScore;
				BlueScore = ui.BlueScore;
				MatchTime = ui.MatchTime;
				Resolution = ui.Resolution;
				Ammo = ui.Ammo;
				break;
			case EMessageType.State:
				auto state = cast(CStateMessage)message;
				auto data = new DataInput(state.StateArray);
				
				auto num_new_objects = data.int32();
				
				foreach(_; 0..num_new_objects)
				{
					auto name = cast(char[])data.array();
					auto id = data.int32;
					Simulation.AddObject(name, id);
				}
				
				auto num_removed_objects = data.int32();
				
				foreach(_; 0..num_removed_objects)
				{
					auto id = data.int32;
					//Stdout("Removing", id).nl;
					Simulation.RemoveObject(id);
				}
				
				Simulation.LoadState(data);
				break;
			default: {}
		}
	}
	
	void Input(ALLEGRO_EVENT* event)
	{
		switch(event.type)
		{
			case ALLEGRO_EVENT_KEY_DOWN:
				scope message = new CInputMessage;
				message.Down = true;				
				
				bool good = true;
				switch(event.keyboard.keycode)
				{
					case ALLEGRO_KEY_UP:
						message.Input = EInput.Up;
						break;
					case ALLEGRO_KEY_LEFT:
						message.Input = EInput.Left;
						break;
					case ALLEGRO_KEY_RIGHT:
						message.Input = EInput.Right;
						break;
					case ALLEGRO_KEY_DOWN:
						message.Input = EInput.Down;
						break;
					case ALLEGRO_KEY_SPACE:
						message.Input = EInput.Launch;
						break;
					case ALLEGRO_KEY_RCTRL:
					case ALLEGRO_KEY_LCTRL:
						message.Input = EInput.Collect;
						break;
					case ALLEGRO_KEY_R:
						message.Input = EInput.Respawn;
						break;
					default:
						good = false;
				}
				
				if(good)
					Channel.Send(message);
				break;
			case ALLEGRO_EVENT_KEY_UP:
				scope message = new CInputMessage;
				message.Down = false;				
				
				bool good = true;
				switch(event.keyboard.keycode)
				{
					case ALLEGRO_KEY_UP:
						message.Input = EInput.Up;
						break;
					case ALLEGRO_KEY_LEFT:
						message.Input = EInput.Left;
						break;
					case ALLEGRO_KEY_RIGHT:
						message.Input = EInput.Right;
						break;
					case ALLEGRO_KEY_DOWN:
						message.Input = EInput.Down;
						break;
					case ALLEGRO_KEY_RCTRL:
					case ALLEGRO_KEY_LCTRL:
						message.Input = EInput.Collect;
						break;
					case ALLEGRO_KEY_SPACE:
						message.Input = EInput.Launch;
						break;
					default:
						good = false;
				}
				
				if(good)
					Channel.Send(message);
				break;
			default: {}
		}
	}
protected:
	bool SentName = false;

	int RedScore = 0;
	int BlueScore = 0;
	int Health = 100;
	int Ammo = 0;
	float MatchTime = 0;
	EGameResolution Resolution = EGameResolution.NotDone;

	CFont Font;
	IGame Game;
	CChannel Channel;
	CSimulation Simulation;
	CBitmap Snowball;
	CBitmap Gauge;
}
