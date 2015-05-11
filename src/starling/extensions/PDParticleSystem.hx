// =================================================================================================
//
//	Starling Framework - Particle System Extension
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.extensions;

import openfl.display3D.Context3DBlendFactor;
import openfl.errors.ArgumentError;
import starling.textures.Texture;
import starling.utils.StarlingUtils;

class PDParticleSystem extends ParticleSystem
{
	private var EMITTER_TYPE_GRAVITY:Int = 0;
	private var EMITTER_TYPE_RADIAL:Int  = 1;
	
	// emitter configuration                            // .pex element name
	private var mEmitterType:Int;                       // emitterType
	private var mEmitterXVariance:Float;               // sourcePositionVariance x
	private var mEmitterYVariance:Float;               // sourcePositionVariance y
	
	// particle configuration
	private var mMaxNumParticles:Int;                   // maxParticles
	private var mLifespan:Float;                       // particleLifeSpan
	private var mLifespanVariance:Float;               // particleLifeSpanVariance
	private var mStartSize:Float;                      // startParticleSize
	private var mStartSizeVariance:Float;              // startParticleSizeVariance
	private var mEndSize:Float;                        // finishParticleSize
	private var mEndSizeVariance:Float;                // finishParticleSizeVariance
	private var mEmitAngle:Float;                      // angle
	private var mEmitAngleVariance:Float;              // angleVariance
	private var mStartRotation:Float;                  // rotationStart
	private var mStartRotationVariance:Float;          // rotationStartVariance
	private var mEndRotation:Float;                    // rotationEnd
	private var mEndRotationVariance:Float;            // rotationEndVariance
	
	// gravity configuration
	private var mSpeed:Float;                          // speed
	private var mSpeedVariance:Float;                  // speedVariance
	private var mGravityX:Float;                       // gravity x
	private var mGravityY:Float;                       // gravity y
	private var mRadialAcceleration:Float;             // radialAcceleration
	private var mRadialAccelerationVariance:Float;     // radialAccelerationVariance
	private var mTangentialAcceleration:Float;         // tangentialAcceleration
	private var mTangentialAccelerationVariance:Float; // tangentialAccelerationVariance
	
	// radial configuration 
	private var mMaxRadius:Float;                      // maxRadius
	private var mMaxRadiusVariance:Float;              // maxRadiusVariance
	private var mMinRadius:Float;                      // minRadius
	private var mMinRadiusVariance:Float;              // minRadiusVariance
	private var mRotatePerSecond:Float;                // rotatePerSecond
	private var mRotatePerSecondVariance:Float;        // rotatePerSecondVariance
	
	// color configuration
	private var mStartColor:ColorArgb;                  // startColor
	private var mStartColorVariance:ColorArgb;          // startColorVariance
	private var mEndColor:ColorArgb;                    // finishColor
	private var mEndColorVariance:ColorArgb;            // finishColorVariance
	
	public var emitterType(get, set):Int;
	public var emitterXVariance(get, set):Float;
	public var emitterYVariance(get, set):Float;
	public var maxNumParticles(get, set):Int;
	public var lifespan(get, set):Float;
	public var lifespanVariance(get, set):Float;
	public var startSize(get, set):Float;
	public var startSizeVariance(get, set):Float;
	public var endSize(get, set):Float;
	public var endSizeVariance(get, set):Float;
	public var emitAngle(get, set):Float;
	public var emitAngleVariance(get, set):Float;
	public var startRotation(get, set):Float;
	public var startRotationVariance(get, set):Float;
	public var endRotation(get, set):Float;
	public var endRotationVariance(get, set):Float; 
	public var speed(get, set):Float;
	public var speedVariance(get, set):Float;
	public var gravityX(get, set):Float;
	public var gravityY(get, set):Float;
	public var radialAcceleration(get, set):Float;
	public var radialAccelerationVariance(get, set):Float;
	public var tangentialAcceleration(get, set):Float;
	public var tangentialAccelerationVariance(get, set):Float;
	public var maxRadius(get, set):Float;
	public var maxRadiusVariance(get, set):Float;
	public var minRadius(get, set):Float;
	public var minRadiusVariance(get, set):Float;
	public var rotatePerSecond(get, set):Float;
	public var rotatePerSecondVariance(get, set):Float;
	public var startColor(get, set):ColorArgb;
	public var startColorVariance(get, set):ColorArgb;
	public var endColor(get, set):ColorArgb;
	public var endColorVariance(get, set):ColorArgb;
	
	public function new(config:Xml, texture:Texture)
	{
		parseConfig(config);
		
		var emissionRate:Float = mMaxNumParticles / mLifespan;
		super(texture, emissionRate, mMaxNumParticles, mMaxNumParticles,
			  mBlendFactorSource, mBlendFactorDestination);
	}
	
	private override function createParticle():Particle
	{
		return new PDParticle();
	}
	
	private override function initParticle(aParticle:Particle):Void
	{
		var particle:PDParticle = cast aParticle; 
	 
		// for performance reasons, the random variances are calculated inline instead
		// of calling a function
		
		var lifespan:Float = mLifespan + mLifespanVariance * (Math.random() * 2.0 - 1.0);
		
		particle.currentTime = 0.0;
		particle.totalTime = lifespan > 0.0 ? lifespan : 0.0;
		
		if (lifespan <= 0.0) return;
		
		particle.x = mEmitterX + mEmitterXVariance * (Math.random() * 2.0 - 1.0);
		particle.y = mEmitterY + mEmitterYVariance * (Math.random() * 2.0 - 1.0);
		particle.startX = mEmitterX;
		particle.startY = mEmitterY;
		
		var angle:Float = mEmitAngle + mEmitAngleVariance * (Math.random() * 2.0 - 1.0);
		var speed:Float = mSpeed + mSpeedVariance * (Math.random() * 2.0 - 1.0);
		particle.velocityX = speed * Math.cos(angle);
		particle.velocityY = speed * Math.sin(angle);
		
		var startRadius:Float = mMaxRadius + mMaxRadiusVariance * (Math.random() * 2.0 - 1.0);
		var endRadius:Float   = mMinRadius + mMinRadiusVariance * (Math.random() * 2.0 - 1.0);
		particle.emitRadius = startRadius;
		particle.emitRadiusDelta = (endRadius - startRadius) / lifespan;
		particle.emitRotation = mEmitAngle + mEmitAngleVariance * (Math.random() * 2.0 - 1.0); 
		particle.emitRotationDelta = mRotatePerSecond + mRotatePerSecondVariance * (Math.random() * 2.0 - 1.0); 
		particle.radialAcceleration = mRadialAcceleration + mRadialAccelerationVariance * (Math.random() * 2.0 - 1.0);
		particle.tangentialAcceleration = mTangentialAcceleration + mTangentialAccelerationVariance * (Math.random() * 2.0 - 1.0);
		
		var startSize:Float = mStartSize + mStartSizeVariance * (Math.random() * 2.0 - 1.0); 
		var endSize:Float = mEndSize + mEndSizeVariance * (Math.random() * 2.0 - 1.0);
		if (startSize < 0.1) startSize = 0.1;
		if (endSize < 0.1)   endSize = 0.1;
		particle.scale = startSize / texture.width;
		particle.scaleDelta = ((endSize - startSize) / lifespan) / texture.width;
		
		// colors
		
		var startColor:ColorArgb = particle.colorArgb;
		var colorDelta:ColorArgb = particle.colorArgbDelta;
		
		startColor.red   = mStartColor.red;
		startColor.green = mStartColor.green;
		startColor.blue  = mStartColor.blue;
		startColor.alpha = mStartColor.alpha;
		
		if (mStartColorVariance.red != 0)   startColor.red   += mStartColorVariance.red   * (Math.random() * 2.0 - 1.0);
		if (mStartColorVariance.green != 0) startColor.green += mStartColorVariance.green * (Math.random() * 2.0 - 1.0);
		if (mStartColorVariance.blue != 0)  startColor.blue  += mStartColorVariance.blue  * (Math.random() * 2.0 - 1.0);
		if (mStartColorVariance.alpha != 0) startColor.alpha += mStartColorVariance.alpha * (Math.random() * 2.0 - 1.0);
		
		var endColorRed:Float   = mEndColor.red;
		var endColorGreen:Float = mEndColor.green;
		var endColorBlue:Float  = mEndColor.blue;
		var endColorAlpha:Float = mEndColor.alpha;

		if (mEndColorVariance.red != 0)   endColorRed   += mEndColorVariance.red   * (Math.random() * 2.0 - 1.0);
		if (mEndColorVariance.green != 0) endColorGreen += mEndColorVariance.green * (Math.random() * 2.0 - 1.0);
		if (mEndColorVariance.blue != 0)  endColorBlue  += mEndColorVariance.blue  * (Math.random() * 2.0 - 1.0);
		if (mEndColorVariance.alpha != 0) endColorAlpha += mEndColorVariance.alpha * (Math.random() * 2.0 - 1.0);
		
		colorDelta.red   = (endColorRed   - startColor.red)   / lifespan;
		colorDelta.green = (endColorGreen - startColor.green) / lifespan;
		colorDelta.blue  = (endColorBlue  - startColor.blue)  / lifespan;
		colorDelta.alpha = (endColorAlpha - startColor.alpha) / lifespan;
		
		// rotation
		
		var startRotation:Float = mStartRotation + mStartRotationVariance * (Math.random() * 2.0 - 1.0); 
		var endRotation:Float   = mEndRotation   + mEndRotationVariance   * (Math.random() * 2.0 - 1.0);
		
		particle.rotation = startRotation;
		particle.rotationDelta = (endRotation - startRotation) / lifespan;
	}
	
	private override function advanceParticle(aParticle:Particle, passedTime:Float):Void
	{
		var particle:PDParticle = cast aParticle;
		
		var restTime:Float = particle.totalTime - particle.currentTime;
		passedTime = restTime > passedTime ? passedTime : restTime;
		particle.currentTime += passedTime;
		
		if (mEmitterType == EMITTER_TYPE_RADIAL)
		{
			particle.emitRotation += particle.emitRotationDelta * passedTime;
			particle.emitRadius   += particle.emitRadiusDelta   * passedTime;
			particle.x = mEmitterX - Math.cos(particle.emitRotation) * particle.emitRadius;
			particle.y = mEmitterY - Math.sin(particle.emitRotation) * particle.emitRadius;
		}
		else
		{
			var distanceX:Float = particle.x - particle.startX;
			var distanceY:Float = particle.y - particle.startY;
			var distanceScalar:Float = Math.sqrt(distanceX*distanceX + distanceY*distanceY);
			if (distanceScalar < 0.01) distanceScalar = 0.01;
			
			var radialX:Float = distanceX / distanceScalar;
			var radialY:Float = distanceY / distanceScalar;
			var tangentialX:Float = radialX;
			var tangentialY:Float = radialY;
			
			radialX *= particle.radialAcceleration;
			radialY *= particle.radialAcceleration;
			
			var newY:Float = tangentialX;
			tangentialX = -tangentialY * particle.tangentialAcceleration;
			tangentialY = newY * particle.tangentialAcceleration;
			
			particle.velocityX += passedTime * (mGravityX + radialX + tangentialX);
			particle.velocityY += passedTime * (mGravityY + radialY + tangentialY);
			particle.x += particle.velocityX * passedTime;
			particle.y += particle.velocityY * passedTime;
		}
		
		particle.scale += particle.scaleDelta * passedTime;
		particle.rotation += particle.rotationDelta * passedTime;
		
		particle.colorArgb.red   += particle.colorArgbDelta.red   * passedTime;
		particle.colorArgb.green += particle.colorArgbDelta.green * passedTime;
		particle.colorArgb.blue  += particle.colorArgbDelta.blue  * passedTime;
		particle.colorArgb.alpha += particle.colorArgbDelta.alpha * passedTime;
		
		particle.color = particle.colorArgb.toRgb();
		particle.alpha = particle.colorArgb.alpha;
	}
	
	private function updateEmissionRate():Void
	{
		emissionRate = mMaxNumParticles / mLifespan;
	}
	
	private function getXMLNode(xml:Xml, string:String):Xml
	{
		for (sourcePositionVariance in xml.elementsNamed(string)) {
			if (sourcePositionVariance.nodeType == Xml.Element ) {
				return sourcePositionVariance;
			}
		}
		return null;
	}
	
	private function parseConfig(root:Xml):Void
	{
		
		var config:Xml = getXMLNode(root, "particleEmitterConfig");
		var sourcePositionVariance:Xml = getXMLNode(config, "sourcePositionVariance");
		mEmitterXVariance = Std.parseFloat(sourcePositionVariance.get("x"));
		mEmitterYVariance = Std.parseFloat(sourcePositionVariance.get("y"));
		var gravity:Xml = getXMLNode(config, "gravity");
		mGravityX = Std.parseFloat(gravity.get("x"));
		mGravityY = Std.parseFloat(gravity.get("y"));
		mEmitterType = getIntValue(getXMLNode(config, "emitterType"));
		mMaxNumParticles = getIntValue(getXMLNode(config, "maxParticles"));
		mLifespan = Math.max(0.01, getFloatValue(getXMLNode(config, "particleLifeSpan")));
		trace(config);
		trace("1");
		mLifespanVariance = getFloatValue(getXMLNode(config, "particleLifespanVariance"));
		trace("2");
		mStartSize = getFloatValue(getXMLNode(config, "startParticleSize"));
		trace("3");
		mStartSizeVariance = getFloatValue(getXMLNode(config, "mStartSizeVariance"));
		trace("4");
		mEndSize = getFloatValue(getXMLNode(config, "mEndSize"));
		trace("5");
		mEndSizeVariance = getFloatValue(getXMLNode(config, "mEndSizeVariance"));
		trace("6");
		mEmitAngle = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "angle")));
		trace("7");
		mEmitAngleVariance = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "angleVariance")));
		trace("8");
		mStartRotation = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "rotationStart")));
		trace("9");
		mStartRotationVariance = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "rotationStartVariance")));
		trace("10");
		mEndRotation = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "mEndRotation")));
		trace("11");
		mEndRotationVariance = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "mEndRotationVariance")));
		trace("12");
		mSpeed = getFloatValue(getXMLNode(config, "speed"));
		trace("13");
		mSpeedVariance = getFloatValue(getXMLNode(config, "speedVariance"));
		trace("14");
		mRadialAcceleration = getFloatValue(getXMLNode(config, "radialAcceleration"));
		trace("15");
		mRadialAccelerationVariance = getFloatValue(getXMLNode(config, "radialAccelVariance"));
		trace("16");
		mTangentialAcceleration = getFloatValue(getXMLNode(config, "tangentialAcceleration"));
		trace("17");
		mTangentialAccelerationVariance = getFloatValue(getXMLNode(config, "tangentialAccelVariance"));
		trace("18");
		mMaxRadius = getFloatValue(getXMLNode(config, "maxRadius"));
		trace("19");
		mMaxRadiusVariance = getFloatValue(getXMLNode(config, "maxRadiusVariance"));
		trace("20");
		mMinRadius = getFloatValue(getXMLNode(config, "minRadius"));
		trace("21");
		mMinRadiusVariance = getFloatValue(getXMLNode(config, "minRadiusVariance"));
		trace("22");
		mRotatePerSecond = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "rotatePerSecond")));
		trace("23");
		mRotatePerSecondVariance = StarlingUtils.deg2rad(getFloatValue(getXMLNode(config, "rotatePerSecondVariance")));
		trace("24");
		mStartColor = getColor(getXMLNode(config, "startColor"));
		trace("25");
		mStartColorVariance = getColor(getXMLNode(config, "startColorVariance"));
		trace("26");
		mEndColor = getColor(getXMLNode(config, "finishColor"));
		trace("27");
		mEndColorVariance = getColor(getXMLNode(config, "finishColorVariance"));
		trace("28");
		mBlendFactorSource = getBlendFunc(getXMLNode(config, "blendFuncSource"));
		trace("29");
		mBlendFactorDestination = getBlendFunc(getXMLNode(config, "blendFuncDestination"));
		
		// compatibility with future Particle Designer versions
		// (might fix some of the uppercase/lowercase typos)
		
		if (Math.isNaN(mEndSizeVariance)){
			mEndSizeVariance = getFloatValue(getXMLNode(config, "finishParticleSizeVariance"));
		}
		if (Math.isNaN(mLifespan)){
			mLifespan = Math.max(0.01, getFloatValue(getXMLNode(config, "particleLifespan")));
		}
		if (Math.isNaN(mLifespanVariance)){
			mLifespanVariance = getFloatValue(getXMLNode(config, "particleLifeSpanVariance"));
		}
		if (Math.isNaN(mMinRadiusVariance)){
			mMinRadiusVariance = 0.0;
		}
	}
	
	private function getIntValue(element:Xml):Int
	{
		if (element == null) return 0;
		return Std.parseInt(element.get("value"));
	}
	
	private function getFloatValue(element:Xml):Float
	{
		if (element == null) return 0;
		return Std.parseFloat(element.get("value"));
	}
	
	private function getColor(element:Xml):ColorArgb
	{
		var color:ColorArgb = new ColorArgb();
		if (element == null) return color;
		color.red   = Std.parseFloat(element.get("red"));
		color.green = Std.parseFloat(element.get("green"));
		color.blue  = Std.parseFloat(element.get("blue"));
		color.alpha = Std.parseFloat(element.get("alpha"));
		return color;
	}
	
	private function getBlendFunc(element:Xml):Context3DBlendFactor
	{
		var value:Int = getIntValue(element);
		trace("value = " + value);
		switch (value)
		{
			case 0:     return Context3DBlendFactor.ZERO;
			case 1:     return Context3DBlendFactor.ONE;
			case 0x300: return Context3DBlendFactor.SOURCE_COLOR;
			case 0x301: return Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
			case 0x302: return Context3DBlendFactor.SOURCE_ALPHA;
			case 0x303: return Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			case 0x304: return Context3DBlendFactor.DESTINATION_ALPHA;
			case 0x305: return Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA;
			case 0x306: return Context3DBlendFactor.DESTINATION_COLOR;
			case 0x307: return Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR;
			default:    throw new ArgumentError("unsupported blending function: " + value);
		}
	}
	
	public function get_emitterType():Int { return mEmitterType; }
	public function set_emitterType(value:Int):Int { return mEmitterType = value; }

	public function get_emitterXVariance():Float { return mEmitterXVariance; }
	public function set_emitterXVariance(value:Float):Float { return mEmitterXVariance = value; }

	public function get_emitterYVariance():Float { return mEmitterYVariance; }
	public function set_emitterYVariance(value:Float):Float { return mEmitterYVariance = value; }

	public function get_maxNumParticles():Int { return mMaxNumParticles; }
	public function set_maxNumParticles(value:Int):Int 
	{ 
		maxCapacity = value;
		mMaxNumParticles = maxCapacity; 
		updateEmissionRate();
		return value;
	}

	public function get_lifespan():Float { return mLifespan; }
	public function set_lifespan(value:Float):Float 
	{ 
		mLifespan = Math.max(0.01, value);
		updateEmissionRate();
		return value;
	}

	public function get_lifespanVariance():Float { return mLifespanVariance; }
	public function set_lifespanVariance(value:Float):Float { return mLifespanVariance = value; }

	public function get_startSize():Float { return mStartSize; }
	public function set_startSize(value:Float):Float { return mStartSize = value; }

	public function get_startSizeVariance():Float { return mStartSizeVariance; }
	public function set_startSizeVariance(value:Float):Float { return  mStartSizeVariance = value; }

	public function get_endSize():Float { return mEndSize; }
	public function set_endSize(value:Float):Float { return mEndSize = value; }

	public function get_endSizeVariance():Float { return mEndSizeVariance; }
	public function set_endSizeVariance(value:Float):Float { return mEndSizeVariance = value; }

	public function get_emitAngle():Float { return mEmitAngle; }
	public function set_emitAngle(value:Float):Float { return mEmitAngle = value; }

	public function get_emitAngleVariance():Float { return mEmitAngleVariance; }
	public function set_emitAngleVariance(value:Float):Float { return mEmitAngleVariance = value; }

	public function get_startRotation():Float { return mStartRotation; } 
	public function set_startRotation(value:Float):Float { return mStartRotation = value; }
	
	public function get_startRotationVariance():Float { return mStartRotationVariance; } 
	public function set_startRotationVariance(value:Float):Float { return mStartRotationVariance = value; }
	
	public function get_endRotation():Float { return mEndRotation; } 
	public function set_endRotation(value:Float):Float { return mEndRotation = value; }
	
	public function get_endRotationVariance():Float { return mEndRotationVariance; } 
	public function set_endRotationVariance(value:Float):Float { return mEndRotationVariance = value; }
	
	public function get_speed():Float { return mSpeed; }
	public function set_speed(value:Float):Float { return mSpeed = value; }

	public function get_speedVariance():Float { return mSpeedVariance; }
	public function set_speedVariance(value:Float):Float { return mSpeedVariance = value; }

	public function get_gravityX():Float { return mGravityX; }
	public function set_gravityX(value:Float):Float { return mGravityX = value; }

	public function get_gravityY():Float { return mGravityY; }
	public function set_gravityY(value:Float):Float { return mGravityY = value; }

	public function get_radialAcceleration():Float { return mRadialAcceleration; }
	public function set_radialAcceleration(value:Float):Float { return mRadialAcceleration = value; }

	public function get_radialAccelerationVariance():Float { return mRadialAccelerationVariance; }
	public function set_radialAccelerationVariance(value:Float):Float { return mRadialAccelerationVariance = value; }

	public function get_tangentialAcceleration():Float { return mTangentialAcceleration; }
	public function set_tangentialAcceleration(value:Float):Float { return mTangentialAcceleration = value; }

	public function get_tangentialAccelerationVariance():Float { return mTangentialAccelerationVariance; }
	public function set_tangentialAccelerationVariance(value:Float):Float { return mTangentialAccelerationVariance = value; }

	public function get_maxRadius():Float { return mMaxRadius; }
	public function set_maxRadius(value:Float):Float { return mMaxRadius = value; }

	public function get_maxRadiusVariance():Float { return mMaxRadiusVariance; }
	public function set_maxRadiusVariance(value:Float):Float { return mMaxRadiusVariance = value; }

	public function get_minRadius():Float { return mMinRadius; }
	public function set_minRadius(value:Float):Float { return mMinRadius = value; }

	public function get_minRadiusVariance():Float { return mMinRadiusVariance; }
	public function set_minRadiusVariance(value:Float):Float { return mMinRadiusVariance = value; }

	public function get_rotatePerSecond():Float { return mRotatePerSecond; }
	public function set_rotatePerSecond(value:Float):Float { return mRotatePerSecond = value; }

	public function get_rotatePerSecondVariance():Float { return mRotatePerSecondVariance; }
	public function set_rotatePerSecondVariance(value:Float):Float { return mRotatePerSecondVariance = value; }

	public function get_startColor():ColorArgb { return mStartColor; }
	public function set_startColor(value:ColorArgb):ColorArgb { return mStartColor = value; }

	public function get_startColorVariance():ColorArgb { return mStartColorVariance; }
	public function set_startColorVariance(value:ColorArgb):ColorArgb { return mStartColorVariance = value; }

	public function get_endColor():ColorArgb { return mEndColor; }
	public function set_endColor(value:ColorArgb):ColorArgb { return mEndColor = value; }

	public function get_endColorVariance():ColorArgb { return mEndColorVariance; }
	public function set_endColorVariance(value:ColorArgb):ColorArgb { return mEndColorVariance = value; }
}