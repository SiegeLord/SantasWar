module game.Util;

import tango.math.Math;

const(char)[] Prop(const(char)[] type, const(char)[] name, const(char)[] get_attr = "", const(char)[] set_attr = "")()
{
	return
	"@property " ~ get_attr ~ "
	" ~ type ~ " " ~ name ~ "()
	{
		return " ~ name ~ "Val;
	}
	
	@property " ~ set_attr ~ "
	" ~ type ~ " " ~ name ~ "(" ~ type ~ " val)
	{
		return " ~ name ~ "Val = val;
	}";
}

T1 Interpolate(T1, T2)(T1 val1, T1 val2, T2 frac)
{
	return val1 + frac * (val2 - val1);
}

void Clamp(T)(ref T val, T max_val)
{
	if(val > max_val)
		val = max_val;
}

void Clamp(T)(ref T val, T min_val, T max_val)
{
	if(val > max_val)
		val = max_val;
	else if(val < min_val)
		val = min_val;
}

T RoundTowards(T)(T val, T to)
{
	if(to > val)
		return ceil(val);
	else
		return floor(val);
}
