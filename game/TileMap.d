module game.TileMap;

import game.ConfigManager;
import game.BitmapManager;
import game.Util;
import game.IGame;
import game.TileSheet;
import game.MathTypes;

import tango.io.Stdout;
import tango.math.Math;
import tango.text.Util;
import tango.text.convert.Format;

import allegro5.allegro;

final class CTileMap
{
	this(const(char)[] file, CTileSheet sheet, CConfigManager config_manager, CBitmapManager bitmap_manager)
	{
		auto cfg = config_manager.Load(file);
		Sheet = sheet;

		Width = max(cfg.width.GetValue!(int)(1), 1);
		Height = max(cfg.height.GetValue!(int)(1), 1);
		
		TileMap.length = Width * Height;
		TileMap[] = 0;
		
		size_t y = 0;
		
		foreach(row_str; lines(cfg.tilemap.GetValue!(const(dchar)[])("")))
		{
			foreach(x, symbol; row_str)
			{
				if(x >= Width)
					break;
				auto tile_idx = Sheet.GetIdx(symbol);
				if(Sheet.GetTile(tile_idx).Flags & ETileFlag.Spawn)
					SpawnSpots ~= SVector2D(x, y);
				if(Sheet.GetTile(tile_idx).Flags & ETileFlag.Health)
					HealthSpots ~= SVector2D(x, y);
				
				TileMap[y * Width + x] = tile_idx;
			}
			
			if(row_str.length > 0)
				y++;
		}
	}
	
	this(CTileSheet sheet, int width, int height, uint[] tilemap)
	{
		Sheet = sheet;
		Width = width;
		Height = height;
		TileMap = tilemap.dup;
	}
	
	void Draw(SVector2D screen_pos, SVector2D screen_size)
	{
		auto tw = TileSize;
		auto th = TileSize;
		
		auto start_x = cast(int)max(0.0f, screen_pos.X / tw);
		auto start_y = cast(int)max(0.0f, screen_pos.Y / th);
		auto end_x = cast(int)min((screen_pos.X + screen_size.X) / tw + 1, Width);
		auto end_y = cast(int)min((screen_pos.Y + screen_size.Y) / th + 1, Height);
		
		bool was_held = al_is_bitmap_drawing_held();
		al_hold_bitmap_drawing(true);
		
		foreach(y; start_y..end_y)
		{
			foreach(x; start_x..end_x)
			{
				Sheet.DrawTile(TileMap[y * Width + x], x * TileSize, y * TileSize);
			}
		}
		
		if(!was_held)
			al_hold_bitmap_drawing(false);
	}
	
	@property
	SVector2D PixelSize()
	{
		return SVector2D(Width * TileSize, Height * TileSize);
	}
	
	CTileSheet.STile GetTile(int x, int y)
	{
		return Sheet.GetTile(TileMap[y * Width + x]);
	}
	
	mixin(Prop!("int", "Width", "", "protected"));
	mixin(Prop!("int", "Height", "", "protected"));
	uint[] TileMap;
	SVector2D[] SpawnSpots;
	SVector2D[] HealthSpots;
protected:
	CTileSheet Sheet;
	int WidthVal;
	int HeightVal;
}
