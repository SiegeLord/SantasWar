module game.Gfx;

import game.Disposable;
import game.Util;
import game.MathTypes;
import tango.io.Stdout;

import allegro5.allegro;
import allegro5.allegro_primitives;

import tango.io.Stdout;
import tango.math.Math;

import game.Config;

class CGfx : CDisposable
{
	this(CConfig cfg)
	{
		if(cfg.GetNodeByReference("gfx:fullscreen").GetValue(false))
			al_set_new_display_flags(ALLEGRO_FULLSCREEN_WINDOW);

		Display = al_create_display(cfg.GetNodeByReference("gfx:screen_w").GetValue(800), cfg.GetNodeByReference("gfx:screen_h").GetValue(640));
		Backbuffer = al_create_bitmap(400, 320);
		Scale = min(cast(int)(al_get_display_width(Display) / al_get_bitmap_width(Backbuffer)), cast(int)(al_get_display_height(Display) / al_get_bitmap_height(Backbuffer)));
		Scale = max(Scale, 1);
		
		al_init_primitives_addon();
		al_set_target_bitmap(Backbuffer);
	}
	
	override
	void Dispose()
	{
		al_destroy_display(Display);
		super.Dispose;
	}
	
	@property
	int ScreenWidth()
	{
		return al_get_bitmap_width(Backbuffer);
	}
	
	@property
	int ScreenHeight()
	{
		return al_get_bitmap_height(Backbuffer);
	}
	
	@property
	SVector2D ScreenSize()
	{
		return SVector2D(ScreenWidth, ScreenHeight);
	}
	
	void ResetTransform()
	{
		ALLEGRO_TRANSFORM identity;
		al_identity_transform(&identity);
		al_use_transform(&identity);
	}
	
	void FlipDisplay()
	{
		al_set_target_bitmap(al_get_backbuffer(Display));
		al_clear_to_color(al_map_rgb_f(0, 0, 0));
		auto x = (al_get_display_width(Display) - Scale * ScreenWidth) / 2;
		auto y = (al_get_display_height(Display) - Scale * ScreenHeight) / 2;
		al_draw_scaled_bitmap(Backbuffer, 0, 0, ScreenWidth, ScreenHeight, x, y, Scale * ScreenWidth, Scale * ScreenHeight, 0);
		al_flip_display();
		al_set_target_bitmap(Backbuffer);
	}
	
	static
	void DrawCircleGradient(float cx, float cy, float r1, float r2, ALLEGRO_COLOR color1, ALLEGRO_COLOR color2)
	{
		assert(r2 > r1);
		
		auto r = (r2 + r1) / 2;
		auto t = r2 - r1;
		
		ALLEGRO_VERTEX[100] vtx;
		auto num_segments = vtx.length / 2;

		al_calculate_arc(&(vtx[0].x), ALLEGRO_VERTEX.sizeof, cx, cy, r, r, 0, PI * 2, t, cast(int)(num_segments));
		foreach(ii; 0..2 * num_segments)
		{
			vtx[ii].color = ii % 2 ? color1 : color2;
			vtx[ii].z = 0;
		}

		al_draw_prim(vtx.ptr, null, null, 0, cast(int)(2 * num_segments), ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_STRIP);
	}

	static
	ALLEGRO_COLOR BlendColors(ALLEGRO_COLOR c1, ALLEGRO_COLOR c2, float frac)
	{
		return al_map_rgba_f(c1.r + (c2.r - c1.r) * frac, 
							 c1.g + (c2.g - c1.g) * frac, 
							 c1.b + (c2.b - c1.b) * frac, 
							 c1.a + (c2.a - c1.a) * frac);
	}
	
	mixin(Prop!("ALLEGRO_DISPLAY*", "Display", "", "protected"));
protected:
	int Scale;

	ALLEGRO_DISPLAY* DisplayVal;
	ALLEGRO_BITMAP* Backbuffer;
}
