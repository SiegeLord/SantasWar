module game.Sprite;

import game.Bitmap;
import game.BitmapManager;
import game.ConfigManager;
import game.Util;
import game.MathTypes;

import tango.io.Path;
import tango.math.Math;

import allegro5.allegro;

final class CSprite
{
	this(const(char)[] file, CConfigManager config_manager, CBitmapManager bmp_manager)
	{
		auto parser = parse(file);
		auto ext = parser.ext();
		if(ext == "cfg")
		{
			auto cfg = config_manager.Load(file);
			auto bmp_name = cfg["bitmap"].GetValue!(const(char)[])("");
			if(bmp_name == "")
				bmp_name = parser.folder() ~ parser.name() ~ ".png";

			auto bmp = bmp_manager.Load(bmp_name);
			this(bmp, cfg["width"].GetValue!(int)(bmp.Width), cfg["height"].GetValue!(int)(bmp.Width), cfg["fps"].GetValue!(float)(0));
			Offset.X = cfg["offset_x"].GetValue!(int)(0);
			Offset.Y = cfg["offset_y"].GetValue!(int)(0);
			Loop = cfg["loop"].GetValue!(bool)(true);
		}
		else
		{
			auto bmp = bmp_manager.Load(file);
			this(bmp, bmp.Width, bmp.Height, 0);
		}
	}
	
	this(CBitmap bitmap, int width, int height, float fps)
	{
		Bitmap = bitmap;
		Width = min(width, Bitmap.Width);
		Height = min(height, Bitmap.Height);
		FPS = fps;
		
		NumX = cast(int)(Bitmap.Width / Width);
		NumY = cast(int)(Bitmap.Height / Height);
	}
	
	void Draw(float time, float cx, float cy, float dx, float dy, float theta, ALLEGRO_COLOR col)
	{
		time -= TimeOffset;
		
		const total = (NumX * NumY);
		int frame_idx = cast(int)(time * FPS);
		if(frame_idx < 0)
			frame_idx += total;
		
		if(Loop)
			frame_idx %= total;
		else
			frame_idx = min(frame_idx, total - 1);
		
		int x_div = frame_idx % NumX;
		int y_div = frame_idx / NumX;
		
		al_draw_tinted_scaled_rotated_bitmap_region(Bitmap.Get, cast(float)x_div * Width, cast(float)y_div * Height, 
		    cast(float)Width, cast(float)Height, col, cx, cy, dx, dy,
		    1.0, 1.0, theta, 0);
	}
	
	void Draw(float time, float cx, float cy, float dx, float dy, float theta)
	{
		Draw(time, cx, cy, dx - Offset.X, dy - Offset.Y, theta, al_map_rgb_f(1, 1, 1));
	}
	
	void Draw(float time, float dx, float dy)
	{
		Draw(time, 0.0, 0.0, dx - Offset.X, dy - Offset.Y, 0.0, al_map_rgb_f(1, 1, 1));
	}
	
	void Draw(float time, float dx, float dy, ALLEGRO_COLOR color)
	{
		Draw(time, 0.0, 0.0, dx - Offset.X, dy - Offset.Y, 0.0, color);
	}
	
	mixin(Prop!("int", "Width", "", "protected"));
	mixin(Prop!("int", "Height", "", "protected"));
	float TimeOffset = 0;
protected:
	int WidthVal = 0;
	int HeightVal = 0;
	
	int NumY = 1;
	int NumX = 1;
	
	bool Loop = true;
	
	float FPS = 0;
	CBitmap Bitmap;
	SVector2D Offset;
}
