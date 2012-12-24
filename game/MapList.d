module game.MapList;

import slconfig;
import Path = tango.io.Path;

struct SMap
{
	const(char)[] Name;
	const(char)[] File;
}

SMap[] GetMaps()
{
	SMap[] ret;
	
	foreach(info; Path.children("maps"))
	{
		auto cfg = SNode();
		scope(exit) cfg.Destroy;
		auto filename = info.path ~ info.name;
		cfg.LoadNodes(filename);
		auto name = cfg["name"].GetValue!(const(char)[])(info.name);
		ret ~= SMap(name, filename);
	}
	
	return ret;
}
