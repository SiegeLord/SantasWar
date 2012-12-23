module game.ComponentFactory;

import game.Component;

alias CComponent function(const(char)[] name, const(char)[] value, bool need_sync) TCreator;

TCreator[char[]] Creators;

CComponent CreatorFunc(T)(const(char)[] name, const(char)[] value, bool need_sync)
{
	return new T(name, value, need_sync);
}

CComponent CreateComponent(const(char)[] type, const(char)[] value, const(char)[] name, bool need_sync)
{
	auto creator_ptr = type in Creators;
	if(creator_ptr is null)
		throw new Exception(type.idup ~ " is not a valid component");
	return (*creator_ptr)(name, value, need_sync);
}

const(char)[] FactorySource(const(char)[][] components...)
{
	const(char)[] ret;
	foreach(component; components)
		ret ~= `import game.components.` ~ component ~ `;`;
	
	ret ~= "shared static this() {";
	foreach(component; components)
		ret ~= `Creators["` ~ component ~ `"] = &CreatorFunc!(C` ~ component ~ `);`;
	
	ret ~= "}";
	return ret;
}

mixin(FactorySource("Bool", "Vector", "String", "Float", "Direction", "AnimationSet", "Explosion"));
