module game.MathTypes;

import tango.math.Math;
import tango.math.IEEE;
import tango.io.Stdout;

struct SVector2D
{
	float X = 0;
	float Y = 0;
	
	void Set(float x, float y)
	{
		X = x;
		Y = y;
	}

	SVector2D Rotate(float cosine, float sine)
	{
		auto t = X * cosine - Y * sine;
		Y = X * sine + Y * cosine;
		X = t;
		
		return this;
	}
	
	SVector2D Rotate(float theta)
	{
		return Rotate(cos(theta), sin(theta));
	}
	
	//rotates this vector by pi/2
	SVector2D MakeNormal()
	{
		float t = Y;
		Y = X;
		X = -t;
		
		return this;
	}
	
	float DotProduct(SVector2D other)
	{
		return X * other.X + Y * other.Y;
	}
	
	float CrossProduct(SVector2D other)
	{
		return X * other.Y - Y * other.X;
	}
	
	float Length()
	{
		return hypot(X, Y);
	}
	
	float LengthSq()
	{
		return X * X + Y * Y;
	}
	
	SVector2D opBinary(immutable(char)[] op)(SVector2D other)
	{
		mixin("return SVector2D(X " ~ op ~ "other.X, Y " ~ op ~ "other.Y);");
	}
	
	SVector2D opBinary(immutable(char)[] op)(float scalar)
	{
		mixin("return SVector2D(X " ~ op ~ "scalar, Y " ~ op ~ "scalar);");
	}
	
	SVector2D opBinaryRight(immutable(char)[] op)(float scalar)
	{
		mixin("return SVector2D(X " ~ op ~ "scalar, Y " ~ op ~ "scalar);");
	}
	
	void opOpAssign(immutable(char)[] op)(SVector2D other)
	{
		mixin("X " ~ op ~ "= other.X; Y " ~ op ~ "= other.Y;");
	}
	
	void opOpAssign(immutable(char)[] op)(float scalar)
	{
		mixin("X " ~ op ~ "= scalar; Y " ~ op ~ "= scalar;");
	}
	
	bool opEquals(SVector2D other)
	{
		return feqrel(X, other.X) && feqrel(Y, other.Y);
	}

	SVector2D opUnary(immutable(char)[] op)() if(op == "-")
	{
		return SVector2D(-X, -Y);
	}

	SVector2D Normalize()
	{
		this /= Length;
		return this;
	}
	
	float opIndex(size_t i)
	{
		if(i == 0)
			return X;
		else
			return Y;	
	}
	
	float opIndexAssign(float val, size_t i)
	{
		if(i == 0)
		{
			X = val;
			return X;
		}
		else
		{
			Y = val;
			return Y;
		}
	}
}

struct SRect
{
	SVector2D Min;
	SVector2D Max;
	
	void Offset(SVector2D offset)
	{
		Min += offset;
		Max += offset;
	}
	
	void Set(SVector2D top_left, SVector2D bottom_right)
	{
		Min = top_left;
		Max = bottom_right;
	}
	
	void Set(float x1, float y1, float x2, float y2)
	{
		Min.Set(x1, y1);
		Max.Set(x2, y2);
	}
	
	void BoundRect(SVector2D[] pts...)
	{
		Min = Max = pts[0];
		foreach(pt; pts[1..$])
		{
			Min.X = min(Min.X, pt.X);
			Min.Y = min(Min.Y, pt.Y);
			Max.X = max(Max.X, pt.X);
			Max.Y = max(Max.Y, pt.Y);
		}
	}
	
	void Union(SRect r)
	{
		Min.X = min(Min.X, r.Min.X);
		Min.Y = min(Min.Y, r.Min.Y);
		Max.X = max(Max.X, r.Max.X);
		Max.Y = max(Max.Y, r.Max.Y);
	}
	
	void Fix()
	{
		float t;
		if(Max.X < Min.X)
		{
			t = Max.X;
			Max.X = Min.X;
			Min.X = t;
		}
		
		if(Max.Y < Min.Y)
		{
			t = Max.Y;
			Max.Y = Min.Y;
			Min.Y = t;
		}
	}
	
	@property
	float Width()
	{
		return Max.X - Min.X;
	}
	
	@property
	float Height()
	{
		return Max.Y - Min.Y;
	}
	
	SVector2D Middle()
	{
		return (Min + Max) / 2;
	}
	
	@property
	SVector2D Size()
	{
		return SVector2D(Width, Height);
	}
	
	bool Collide(SVector2D pt)
	{
		return pt.X >= Min.X && pt.Y >= Min.Y && pt.X < Max.X && pt.Y < Max.Y;
	}
	
	bool Collide(SRect r)
	{
		return Min.X < r.Max.X && Min.Y < r.Max.Y && Max.X > r.Min.X && Max.Y > r.Min.Y;
	}
	
	bool CollideBounds(SRect r)
	{
		return Collide(r) && (r.Min.X < Min.X || r.Min.Y < Min.Y || r.Max.X > Max.X || r.Max.Y > Max.Y);
	}
}

unittest
{
	SVector2D vec;
	vec.Set(0, 0);
	vec += SVector2D(1, 2);
	assert(vec == SVector2D(1, 2));
	
	SRect r1;
	SRect r2;
	r1.Set(0, 0, 100, 100);
	r2.Set(50, 50, 100, 100);
	assert(r1.Collide(r2));
	assert(!r1.CollideBounds(r2));
	r2.Set(100, 0, 200, 100);
	assert(!r1.Collide(r2));
	assert(!r1.CollideBounds(r2));
	r2.Set(10, 10, 90, 90);
	assert(r1.Collide(r2));
	assert(!r1.CollideBounds(r2));
	r2.Set(50, 10, 150, 90);
	assert(r1.Collide(r2));
	assert(r1.CollideBounds(r2));
}
