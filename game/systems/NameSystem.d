module game.systems.NameSystem;

import game.System;
import game.IGame;
import game.FontManager;
import game.Font;
import game.GameObject;

import game.components.Vector;
import game.components.String;
import game.components.Float;

import allegro5.allegro;
import allegro5.allegro_font;
import allegro5.d_util;

import tango.core.Array;
import tango.io.Stdout;

class CNameSystem : CSystem
{
	this(IGame game)
	{
		Font = game.FontManager.Load("fonts/pzim3x5.ttf", -6);
	}
	
	struct SObject
	{
		CGameObject GameObject;
		CVector DrawPosition;
		CString Name;
		CFloat Team;
	}
	
	override
	void AddObject(CGameObject object)
	{
		CVector draw_position;
		CString name;
		CFloat team;
		if(object.Get("draw_position", draw_position) && object.Get("name", name) && object.Get("team", team))
		{
			Refs ~= SObject(object, draw_position, name, team);
			object.DeathEvent.Register(&RemoveObject);
		}
	}
	
	override
	void Draw()
	{
		foreach(obj; Refs)
		{
			ALLEGRO_COLOR col;
			if(obj.Team.Value > 0)
				col = al_map_rgb_f(0, 0, 1);
			else
				col = al_map_rgb_f(1, 0, 0);
			
			ALLEGRO_USTR_INFO info;
			al_draw_ustr(Font.Get, col, obj.DrawPosition.X * TileSize + 8, obj.DrawPosition.Y * TileSize - 6, ALLEGRO_ALIGN_CENTRE, dstr_to_ustr(&info, obj.Name.Value));
		}
	}
	
	override
	void RemoveObject(CGameObject object)
	{
		size_t new_size = Refs.partition((SObject holder) => holder.GameObject !is object);
		Refs.length = new_size;
	}
protected:
	SObject[] Refs;
	CFont Font;
}
