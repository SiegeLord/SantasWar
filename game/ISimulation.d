module game.ISimulation;

import game.GameObject;

interface ISimulation
{
	int GetHeight(int x, int y);
	CGameObject AddObject(const(char)[] object_name, int id = -1);
	void RemoveObject(int id);
	bool OnServer();
	void Damage(int x, int y, float damage);
}
