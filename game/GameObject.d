module game.GameObject;

import game.UnorderedEvent;
import game.Component;
import game.ComponentFactory;
import game.Util;
import game.ISimulation;

import game.Config;

import slconfig;

import tango.io.Stdout;
import tango.io.stream.Data;

class CGameObject
{
	this(ISimulation sim, const(char)[] name, CConfig cfg, bool server, int id)
	{
		Name = name;
		Simulation = sim;
		Id = id;
		
		void add_components(SNode node, bool need_sync)
		{
			foreach(comp; node)
			{
				auto component = CreateComponent(comp.Type, comp.GetValue(), comp.Name, need_sync);
				if(need_sync)
					SyncComponents ~= component;
				Components ~= component;
			}
		}
		
		auto sync_node = cfg.Sync;
		if(sync_node.Valid && sync_node.IsAggregate)
			add_components(sync_node, true);
		
		SNode other_node;
		if(server)
			other_node = cfg.Server;
		else
			other_node = cfg.Client;
		
		if(other_node.Valid && other_node.IsAggregate)
			add_components(other_node, false);
		
		DeathEvent = new typeof(DeathEvent);
	}
	
	@property
	TComp Get(TComp)(const(char)[] name)
	{
		TComp ret = null;
		foreach(component; Components)
		{
			if((ret = cast(TComp)component) !is null && ret.Name == name)
				return ret;
		}
		return null;
	}
	
	bool Get(TComp)(const(char)[] name, ref TComp comp)
	{
		return (comp = Get!(TComp)(name)) !is null;
	}
	
	@property
	bool NeedSync()
	{
		return SyncComponents.length > 0;
	}
	
	void SaveState(DataOutput data)
	{
		foreach(comp; SyncComponents)
			comp.SaveState(data);
	}
	
	void LoadState(DataInput data)
	{
		foreach(comp; SyncComponents)
			comp.LoadState(data);
	}
	
	mixin(Prop!("int", "Id", "", "protected"));
	mixin(Prop!("const(char)[]", "Name", "", "protected"));
	CUnorderedEvent!(CGameObject) DeathEvent;
protected:
	const(char)[] NameVal;
	ISimulation Simulation;
	int IdVal;
	CComponent[] SyncComponents;
	CComponent[] Components;
}
