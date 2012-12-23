module game.Simulation;

import game.GameObject;
import game.ConfigManager;
import game.ISimulation;
import game.IGame;
import game.TileMap;
import game.System;
import game.UnorderedEvent;
import game.MathTypes;
import game.Util;

import game.systems.PlayerSystem;
import game.systems.NameSystem;
import game.systems.MovementSystem;
import game.systems.DrawMovementSystem;
import game.systems.CollisionSystem;
import game.systems.LauncherSystem;
import game.systems.DrawSnowballSystem;
import game.systems.SnowballSystem;
import game.systems.HealthSystem;
import game.systems.DrawHealthSystem;
import game.systems.ExplosionSystem;
import game.systems.DrawExplosionSystem;
import game.systems.DamageSystem;
import game.systems.AmmoSystem;

import game.components.Vector;

import game.Config;

import tango.core.Array;
import tango.io.Stdout;
import tango.io.stream.Data;
import Random = tango.math.random.Random;

class CSimulation : ISimulation
{
	this(IGame game, bool on_server)
	{
		OnServer = on_server;
		Game = game;
		Systems ~= new CDrawExplosionSystem(game);
		Systems ~= new CPlayerSystem(game);
		Systems ~= new CNameSystem(game);
		Systems ~= new CLauncherSystem(game, this);
		Systems ~= new CMovementSystem(game, this);
		Systems ~= new CDrawMovementSystem(game);
		Systems ~= new CDrawSnowballSystem(game, this);
		Systems ~= new CSnowballSystem(game, this);
		Systems ~= new CAmmoSystem(game);
		Systems ~= new CHealthSystem(game, this);
		Systems ~= new CDrawHealthSystem(game);
		Systems ~= new CExplosionSystem(game, this);
		
		
		CollisionSystem = new CCollisionSystem(game);
		Systems ~= CollisionSystem;
		
		DamageSystem = new CDamageSystem(game, this);
		Systems ~= DamageSystem;
		
		ObjectAddedEvent = new CUnorderedEvent!(CGameObject);
		ObjectRemovedEvent = new CUnorderedEvent!(CGameObject);
	}
	
	void CreateMap(const(char)[] tilemap)
	{
		TileMap = new CTileMap(tilemap, Game.TileSheet, Game.ConfigManager, Game.BitmapManager);
		AddHealth();
	}
	
	void CreateMap(int width, int height, uint[] tilemap)
	{
		TileMap = new CTileMap(Game.TileSheet, width, height, tilemap);
		AddHealth();
	}
	
	void AddHealth()
	{
		foreach(spot; TileMap.HealthSpots)
		{
			auto obj = AddObject("objects/health.cfg");
			CVector position;
			if(obj.Get("position", position))
				position.Value = spot;
		}
	}
	
	override
	CGameObject AddObject(const(char)[] object_name, int id = -1)
	{
		//Stdout.formatln("Added {} on {}", object_name, OnServer ? "server" : "client");
		if(id < 0)
		{
			id = UnusedId;
			UnusedId++;
		}
		else
		{
			if((id in ObjectRegistry) !is null)
				throw new Exception("This object already exists...");
			if(id > UnusedId)
				UnusedId = id + 1;
		}
		
		auto object = new CGameObject(this, object_name, Game.ConfigManager.Load(object_name), OnServer, id);
		
		ObjectRegistry[id] = object;
		Objects ~= object;
		
		if(object.NeedSync)
		{
			SyncObjects ~= object;
			ObjectAddedEvent.Trigger(object);
		}
		
		foreach(system; Systems)
			system.AddObject(object);
		
		return object;
	}
	
	override
	void RemoveObject(int id)
	{
		auto obj_ptr = id in ObjectRegistry;
		if(obj_ptr is null)
			throw new Exception("No such object...");
		
		auto object = *obj_ptr;
		
		//Stdout("Simulation removing,", id, "Need sync:", object.NeedSync, "Server", OnServer).nl;
		
		if(object.NeedSync)
			ObjectRemovedEvent.Trigger(object);
		
		object.DeathEvent.Trigger(object);
		
		ObjectRegistry.remove(id);
		auto new_size = Objects.partition((CGameObject o) => o != object);
		Objects.length = new_size;
		
		new_size = SyncObjects.partition((CGameObject o) => o != object);
		SyncObjects.length = new_size;
	}
	
	void Logic(float dt)
	{
		foreach(system; Systems)
			system.Logic(dt);
	}
	
	void Draw()
	{
		if(TileMap !is null)
			TileMap.Draw(SVector2D(0, 0), SVector2D(800, 600));
		
		foreach(system; Systems)
			system.Draw();
	}
	
	void SaveState(DataOutput data)
	{
		data.int32(cast(int)SyncObjects.length);
		foreach(object; SyncObjects)
		{
			data.int32(object.Id);
			object.SaveState(data);
		}
	}
	
	void LoadState(DataInput data)
	{
		auto num_objs = data.int32();
		assert(num_objs == SyncObjects.length);
		
		foreach(_; 0..num_objs)
		{
			auto id = data.int32();
			auto obj_ptr = id in ObjectRegistry;
			if(obj_ptr is null)
				throw new Exception("Object doesn't exist...");
			(*obj_ptr).LoadState(data);
		}
	}
	
	override
	int GetHeight(int x, int y)
	{
		if(x < 0 || y < 0 || x >= TileMap.Width || y >= TileMap.Height)
			return int.max;
		
		auto ret = TileMap.GetTile(x, y).Height;
		if(ret == 0)
			return CollisionSystem.GetHeight(x, y);
		else
			return ret;
	}
	
	override
	void Damage(int x, int y, float damage)
	{
		DamageSystem.Damage(x, y, damage);
	}
	
	SVector2D GetSpawnSpot()
	{
		if(TileMap.SpawnSpots.length == 0)
			throw new Exception("Map needs spawn spots");

		return TileMap.SpawnSpots[Random.rand.uniformR(TileMap.SpawnSpots.length)];
	}
	
	CGameObject GetObject(int id)
	{
		auto obj_ptr = id in ObjectRegistry;
		return obj_ptr is null ? null : *obj_ptr;
	}
	
	CUnorderedEvent!(CGameObject) ObjectRemovedEvent;
	CUnorderedEvent!(CGameObject) ObjectAddedEvent;
	CGameObject[] SyncObjects;
	CTileMap TileMap;
	
	mixin(Prop!("bool", "OnServer", "override", "protected"));
protected:
	CDamageSystem DamageSystem;
	CCollisionSystem CollisionSystem;
	int UnusedId = 0;
	CGameObject[int] ObjectRegistry;
	CGameObject[] Objects;
	CSystem[] Systems;
	IGame Game;
	bool OnServerVal;
}
