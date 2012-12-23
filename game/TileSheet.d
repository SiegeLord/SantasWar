module game.TileSheet;

import game.IGame;
import game.Bitmap;
import game.BitmapManager;
import game.ConfigManager;
import game.Util;

import tango.text.convert.Format;
import tango.text.convert.Utf;
import tango.math.Math;

import allegro5.allegro;

enum ETileFlag : int
{
	Spawn = 0x01,
	Health = 0x02
}

final class CTileSheet
{
	this(const(char)[] file, CConfigManager config_manager, CBitmapManager bmp_manager)
	{
		auto cfg = config_manager.Load(file);
		auto bmp_name = cfg.bitmap.GetValue!(const(char)[])("");
		if(bmp_name == "")
			throw new Exception("'" ~ file.idup ~ "' needs to specify a bitmap file.");
		
		Bitmap = bmp_manager.Load(bmp_name);
		
		if(TileSize > Bitmap.Width || TileSize > Bitmap.Height)
			throw new Exception("Bitmap is smaller than tile size");
		
		int num_x = Bitmap.Width / TileSize;
		int num_y = Bitmap.Height / TileSize;
		
		Tiles.length = num_x * num_y;
		NumX = num_x;
		
		foreach(idx, ref tile; Tiles)
		{
			tile.X = TileSize * (idx % num_x);
			tile.Y = TileSize * (idx / num_x);
			auto tile_node = cfg[Format("tile_{}", idx)];
			if(tile_node.Valid)
			{
				auto symbol_str = tile_node.symbol.GetValue!(const(dchar)[])("");
				if(symbol_str.length > 0)
					SymbolMap[symbol_str[0]] = cast(uint)idx;
				tile.Height = tile_node.height.GetValue!(int)(0);
				tile.Flags = tile_node.flags.GetValue!(int)(0);
			}
		}
	}
	
	struct STile
	{
		float X;
		float Y;
		int Height;
		int Flags;
	}
	
	void DrawTile(size_t idx, float x, float y)
	{
		auto tile = GetTile(idx);
		al_draw_bitmap_region(Bitmap.Get, tile.X, tile.Y, TileSize, TileSize, x, y, 0);
	}
	
	STile GetTile(float x, float y)
	{
		size_t tile_x = cast(size_t)max(0, floor(x / TileSize));
		size_t tile_y = cast(size_t)max(0, floor(y / TileSize));
		
		return GetTile(tile_x, tile_y);
	}
	
	STile GetTile(size_t x, size_t y)
	{
		return Tiles[y * NumX + x];
	}
	
	STile GetTile(size_t idx)
	{
		return Tiles[idx];
	}
	
	uint GetIdx(dchar symbol)
	{
		auto idx_ptr = symbol in SymbolMap;
		if(idx_ptr is null)
		{
			char[6] buf;
			throw new Exception("Symbol " ~ encode(buf, symbol).idup ~ " is not present in this tilesheet.");
		}
		return *idx_ptr; 
	}
	
protected:
	int NumX;
	CBitmap Bitmap;
	STile[] Tiles;
	uint[dchar] SymbolMap;
}

