module game.ConfigManager;

import game.ResourceManager;

import game.Config;

class CConfigManager : CResourceManager!(CConfig)
{
	this(CConfigManager parent = null)
	{
		super(parent);
	}
	
	CConfig Load(const(char)[] filename)
	{
		auto ret = LoadExisting(filename);
		if(ret is null)
		{
			auto cfg = new CConfig;
			cfg.LoadNodes(filename);
			return Insert(filename, cfg);
		}
		else
		{
			return ret;
		}
	}
	
protected:
	override
	void Destroy(CConfig cfg)
	{
		cfg.Dispose();
	}
}
