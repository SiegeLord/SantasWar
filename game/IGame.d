module game.IGame;

import game.Gfx;
import game.ConfigManager;
import game.FontManager;
import game.BitmapManager;
import game.TileSheet;

import game.Config;

enum EMode
{
	Game,
	Menu,
	Exit,
	Dedicated
}

enum EGameType
{
	Single,
	Join,
	Host
}

enum EGameResolution
{
	NotDone,
	RedWins,
	BlueWins
}

enum TileSize = 16;
enum FixedDt = 1.0f/60.0f;

interface IGame
{
	double Time();
	
	@property
	CGfx Gfx();
	
	@property
	CConfig Options();
	
	@property
	CConfigManager ConfigManager();
	
	@property
	CFontManager FontManager();
	
	@property
	CBitmapManager BitmapManager();
	
	@property
	CTileSheet TileSheet();
	
	@property
	const(char)[] PlayerName();
	
	@property
	const(char)[] PlayerName(const(char)[] name);
	
	@property
	const(char)[] HostName();
	
	@property
	const(char)[] HostName(const(char)[] name);
	
	@property
	EGameType GameType();
	
	@property
	EGameType GameType(EGameType type);
	
	@property
	ushort Port();
	
	@property
	int MatchDuration();
	
	@property
	int MatchDuration(int);
	
	@property
	const(char)[] Map();
	
	@property
	const(char)[] Map(const(char)[] map);
}
