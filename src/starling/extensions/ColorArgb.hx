// =================================================================================================
//
//	Starling Framework - Particle System Extension
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.extensions;

class ColorArgb
{
	public var red:Float;
	public var green:Float;
	public var blue:Float;
	public var alpha:Float;
	
	public static function FromRgb(color:UInt):ColorArgb
	{
		var rgb:ColorArgb = new ColorArgb();
		rgb.fromRgb(color);
		return rgb;
	}
	
	public static function FromArgb(color:UInt):ColorArgb
	{
		var argb:ColorArgb = new ColorArgb();
		argb.fromArgb(color);
		return argb;
	}
	
	public function new(red:Float=0, green:Float=0, blue:Float=0, alpha:Float=0)
	{
		this.red = red;
		this.green = green;
		this.blue = blue;
		this.alpha = alpha;
	}
	
	public function toRgb():UInt
	{
		var r:Float = red;
		if (r < 0.0) r = 0.0;
		else if (r > 1.0) r = 1.0;
		
		var g:Float = green;
		if (g < 0.0) g = 0.0;
		else if (g > 1.0) g = 1.0;
		
		var b:Float = blue;
		if (b < 0.0) b = 0.0;
		else if (b > 1.0) b = 1.0;
		
		return cast(r * 255, Int) << 16 | cast(g * 255, Int) << 8 | cast(b * 255, Int);
	}
	
	public function toArgb():UInt
	{
		var a:Float = alpha;
		if (a < 0.0) a = 0.0; 
		else if (a > 1.0) a = 1.0;
		
		var r:Float = red;
		if (r < 0.0) r = 0.0; 
		else if (r > 1.0) r = 1.0;
		
		var g:Float = green;
		if (g < 0.0) g = 0.0;
		else if (g > 1.0) g = 1.0;
		
		var b:Float = blue;
		if (b < 0.0) b = 0.0;
		else if (b > 1.0) b = 1.0;
		
		return cast(a * 255, Int) << 24 | cast(r * 255, Int) << 16 | cast(g * 255, Int) << 8 | cast(b * 255, Int);
	}
	
	public function fromRgb(color:UInt):Void
	{
		red = (color >> 16 & 0xFF) / 255.0;
		green = (color >> 8 & 0xFF) / 255.0;
		blue = (color & 0xFF) / 255.0;
	}
	
	public function fromArgb(color:UInt):Void
	{
		red = (color >> 16 & 0xFF) / 255.0;
		green = (color >> 8 & 0xFF) / 255.0;
		blue = (color & 0xFF) / 255.0;
		alpha = (color >> 24 & 0xFF) / 255.0;
	}
	
	public function copyFrom(argb:ColorArgb):Void
	{
		red = argb.red;
		green = argb.green;
		blue = argb.blue;
		alpha = argb.alpha;
	}
}