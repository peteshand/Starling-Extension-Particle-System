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

import haxe.Constraints.Function;
import openfl.display3D._shaders.AGLSLShaderUtils;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.errors.ArgumentError;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.AGALMiniAssembler;
import openfl.Vector;
import starling.animation.IAnimatable;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.errors.MissingContextError;
import starling.events.Event;
import starling.textures.Texture;
import starling.textures.TextureSmoothing;
import starling.utils.MatrixUtil;
import starling.utils.VertexData;

/** Dispatched when emission of particles is finished. */
//[Event(name="complete", type="starling.events.Event")]

class ParticleSystem extends DisplayObject implements IAnimatable
{
	public static var MAX_NUM_PARTICLES:Int = 16383;
	
	private var mTexture:Texture;
	private var mParticles:Vector<Particle>;
	private var mFrameTime:Float;
	
	private var mProgram:Program3D;
	private var mVertexData:VertexData;
	private var mVertexBuffer:VertexBuffer3D;
	private var mIndices:Vector<UInt>;
	private var mIndexBuffer:IndexBuffer3D;
	
	private var mNumParticles:Int;
	private var mMaxCapacity:Int;
	private var mEmissionRate:Float; // emitted particles per second
	private var mEmissionTime:Float;
	
	/** Helper objects. */
	private static var sHelperMatrix:Matrix = new Matrix();
	private static var sHelperPoint:Point = new Point();
	private static var _sRenderAlpha:Vector<Float>;
	private static var sRenderAlpha(get, set):Vector<Float>;
	
	private var mEmitterX:Float;
	private var mEmitterY:Float;
	private var mBlendFactorSource:Context3DBlendFactor;
	private var mBlendFactorDestination:Context3DBlendFactor;
	private var mSmoothing:String;
	
	
	public var isEmitting(get, null):Bool;
	public var capacity(get, null):Int;
	public var numParticles(get, null):Int;
	
	public var maxCapacity(get, set):Int;
	public var emissionRate(get, set):Float;
	public var emitterX(get, set):Float;
	public var emitterY(get, set):Float;
	public var blendFactorSource(get, set):Context3DBlendFactor;
	public var blendFactorDestination(get, set):Context3DBlendFactor;
	public var texture(get, set):Texture;
	public var smoothing(get, set):String;
	
	static function get_sRenderAlpha():Vector<Float> 
	{
		if (_sRenderAlpha == null) {
			_sRenderAlpha.push(1.0);
			_sRenderAlpha.push(1.0);
			_sRenderAlpha.push(1.0);
			_sRenderAlpha.push(1.0);
		}
		return _sRenderAlpha;
	}
	
	static function set_sRenderAlpha(value:Vector<Float>):Vector<Float> 
	{
		return _sRenderAlpha = value;
	}
	
	
	public function new(texture:Texture, emissionRate:Float, 
								   initialCapacity:Int=128, maxCapacity:Int=16383,
								   blendFactorSource:Context3DBlendFactor=null, blendFactorDest:Context3DBlendFactor=null)
	{
		super();
		
		if (texture == null) throw new ArgumentError("texture must not be null");
		
		mTexture = texture;
		mParticles = new Vector<Particle>(0, false);
		mVertexData = new VertexData(0);
		mIndices = [];
		mEmissionRate = emissionRate;
		mEmissionTime = 0.0;
		mFrameTime = 0.0;
		mEmitterX = mEmitterY = 0;
		mMaxCapacity = cast Math.min(MAX_NUM_PARTICLES, maxCapacity);
		mSmoothing = TextureSmoothing.BILINEAR;
		if (blendFactorSource != null) mBlendFactorSource = blendFactorSource
		else mBlendFactorSource = Context3DBlendFactor.ONE;
		
		if (blendFactorDest != null) mBlendFactorSource = blendFactorDest; //mBlendFactorSource      = blendFactorSource || Context3DBlendFactor.ONE;
		else mBlendFactorDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA; //mBlendFactorDestination = blendFactorDest   || Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
		
		createProgram();
		updatePremultipliedAlpha();
		raiseCapacity(initialCapacity);

		// handle a lost device context
		Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
			onContextCreated, false, 0, true);
	}

	public override function dispose():Void
	{
		Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		
		if (mVertexBuffer != null) mVertexBuffer.dispose();
		if (mIndexBuffer != null)  mIndexBuffer.dispose();
		
		super.dispose();
	}
	
	private function onContextCreated(event:Dynamic):Void
	{
		createProgram();
		raiseCapacity(0);
	}

	private function updatePremultipliedAlpha():Void
	{
		var pma:Bool = mTexture.premultipliedAlpha;

		// Particle Designer uses special logic for a certain blend factor combination
		if (mBlendFactorSource == Context3DBlendFactor.ONE &&
				mBlendFactorDestination == Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA)
		{
			mVertexData.premultipliedAlpha = mTexture.premultipliedAlpha;
			if (!pma) mBlendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
		}
		else
		{
			mVertexData.premultipliedAlpha = false;
		}
	}
	
	private function createParticle():Particle
	{
		return new Particle();
	}
	
	private function initParticle(particle:Particle):Void
	{
		particle.x = mEmitterX;
		particle.y = mEmitterY;
		particle.currentTime = 0;
		particle.totalTime = 1;
		particle.color = cast Math.random() * 0xffffff;
	}

	private function advanceParticle(particle:Particle, passedTime:Float):Void
	{
		particle.y += passedTime * 250;
		particle.alpha = 1.0 - particle.currentTime / particle.totalTime;
		particle.scale = 1.0 - particle.alpha; 
		particle.currentTime += passedTime;
	}
	
	private function raiseCapacity(byAmount:Int):Void
	{
		var oldCapacity:Int = capacity;
		var newCapacity:Int = cast Math.min(mMaxCapacity, oldCapacity + byAmount);
		var context:Context3D = Starling.Context;
		
		if (context == null) throw new MissingContextError();

		var baseVertexData:VertexData = new VertexData(4);
		baseVertexData.setTexCoords(0, 0.0, 0.0);
		baseVertexData.setTexCoords(1, 1.0, 0.0);
		baseVertexData.setTexCoords(2, 0.0, 1.0);
		baseVertexData.setTexCoords(3, 1.0, 1.0);
		mTexture.adjustVertexData(baseVertexData, 0, 4);
		
		mParticles.fixed = false;
		mIndices.fixed = false;
		
		for (i in oldCapacity...newCapacity) 
		{
			var numVertices:Int = i * 4;
			var numIndices:Int  = i * 6;
			
			mParticles[i] = createParticle();
			mVertexData.append(baseVertexData);
			
			mIndices[cast(numIndices+0, Int)] = numVertices;
			mIndices[cast(numIndices+1, Int)] = numVertices + 1;
			mIndices[cast(numIndices+2, Int)] = numVertices + 2;
			mIndices[cast(numIndices+3, Int)] = numVertices + 1;
			mIndices[cast(numIndices+4, Int)] = numVertices + 3;
			mIndices[cast(numIndices+5, Int)] = numVertices + 2;
		}

		if (newCapacity < oldCapacity)
		{
			mParticles.length = newCapacity;
			mIndices.length = newCapacity * 6;
		}
		
		mParticles.fixed = true;
		mIndices.fixed = true;
		
		// upload data to vertex and index buffers
		
		if (mVertexBuffer != null) mVertexBuffer.dispose();
		if (mIndexBuffer != null)  mIndexBuffer.dispose();

		if (newCapacity > 0)
		{
			mVertexBuffer = context.createVertexBuffer(newCapacity * 4, VertexData.ELEMENTS_PER_VERTEX);
			mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, newCapacity * 4);

			mIndexBuffer  = context.createIndexBuffer(newCapacity * 6);
			mIndexBuffer.uploadFromVector(mIndices, 0, newCapacity * 6);
		}
	}
	
	/** Starts the emitter for a certain time. @default infinite time */
	public function start(duration:Float=-1):Void
	{
		if (duration == -1) duration = 2147483647;
		if (mEmissionRate != 0)                
			mEmissionTime = duration;
	}
	
	/** Stops emitting new particles. Depending on 'clearParticles', the existing particles
	 *  will either keep animating until they die or will be removed right away. */
	public function stop(clearParticles:Bool=false):Void
	{
		mEmissionTime = 0.0;
		if (clearParticles) clear();
	}
	
	/** Removes all currently active particles. */
	public function clear():Void
	{
		mNumParticles = 0;
	}
	
	/** Returns an empty rectangle at the particle system's position. Calculating the
	 *  actual bounds would be too expensive. */
	public override function getBounds(targetSpace:DisplayObject, 
									   resultRect:Rectangle=null):Rectangle
	{
		if (resultRect == null) resultRect = new Rectangle();
		
		getTransformationMatrix(targetSpace, sHelperMatrix);
		MatrixUtil.transformCoords(sHelperMatrix, 0, 0, sHelperPoint);
		
		resultRect.x = sHelperPoint.x;
		resultRect.y = sHelperPoint.y;
		resultRect.width = resultRect.height = 0;
		
		return resultRect;
	}
	
	public function advanceTime(passedTime:Float):Void
	{
		var particleIndex:Int = 0;
		var particle:Particle;
		
		// advance existing particles
		
		while (particleIndex < mNumParticles)
		{
			particle = cast (mParticles[particleIndex], Particle);
			
			if (particle.currentTime < particle.totalTime)
			{
				advanceParticle(particle, passedTime);
				++particleIndex;
			}
			else
			{
				if (particleIndex != mNumParticles - 1)
				{
					var nextParticle:Particle = cast mParticles[cast((mNumParticles-1), Int)];
					mParticles[cast(mNumParticles-1)] = particle;
					mParticles[particleIndex] = nextParticle;
				}
				
				--mNumParticles;

				if (mNumParticles == 0 && mEmissionTime == 0)
					dispatchEventWith(Event.COMPLETE);
			}
		}
		
		// create and advance new particles
		
		if (mEmissionTime > 0)
		{
			var timeBetweenParticles:Float = 1.0 / mEmissionRate;
			mFrameTime += passedTime;
			
			while (mFrameTime > 0)
			{
				if (mNumParticles < mMaxCapacity)
				{
					if (mNumParticles == capacity)
						raiseCapacity(capacity);
				
					particle = cast mParticles[mNumParticles];
					initParticle(particle);
					
					// particle might be dead at birth
					if (particle.totalTime > 0.0)
					{
						advanceParticle(particle, mFrameTime);
						++mNumParticles;
					}
				}
				
				mFrameTime -= timeBetweenParticles;
			}
			
			if (mEmissionTime != 2147483647)
				mEmissionTime = Math.max(0.0, mEmissionTime - passedTime);

			if (mNumParticles == 0 && mEmissionTime == 0)
				dispatchEventWith(Event.COMPLETE);
		}

		// update vertex data
		
		var vertexID:Int = 0;
		var color:UInt;
		var alpha:Float;
		var rotation:Float;
		var x:Float, y:Float;
		var xOffset:Float, yOffset:Float;
		var textureWidth:Float = mTexture.width;
		var textureHeight:Float = mTexture.height;
		
		for (i in 0...mNumParticles) 
		{
			vertexID = i << 2;
			particle = cast mParticles[i];
			color = particle.color;
			alpha = particle.alpha;
			rotation = particle.rotation;
			x = particle.x;
			y = particle.y;
			xOffset = cast (textureWidth  * particle.scale) >> 1;
			yOffset = cast (textureHeight * particle.scale) >> 1;
			
			for (j in 0...4)
				mVertexData.setColorAndAlpha(vertexID+j, color, alpha);
			
			if (Math.isNaN(rotation) == false)
			{
				var cos:Float  = Math.cos(rotation);
				var sin:Float  = Math.sin(rotation);
				var cosX:Float = cos * xOffset;
				var cosY:Float = cos * yOffset;
				var sinX:Float = sin * xOffset;
				var sinY:Float = sin * yOffset;
				
				mVertexData.setPosition(vertexID,   x - cosX + sinY, y - sinX - cosY);
				mVertexData.setPosition(vertexID+1, x + cosX + sinY, y + sinX - cosY);
				mVertexData.setPosition(vertexID+2, x - cosX - sinY, y - sinX + cosY);
				mVertexData.setPosition(vertexID+3, x + cosX - sinY, y + sinX + cosY);
			}
			else 
			{
				// optimization for rotation == 0
				mVertexData.setPosition(vertexID,   x - xOffset, y - yOffset);
				mVertexData.setPosition(vertexID+1, x + xOffset, y - yOffset);
				mVertexData.setPosition(vertexID+2, x - xOffset, y + yOffset);
				mVertexData.setPosition(vertexID+3, x + xOffset, y + yOffset);
			}
		}
	}
	
	public override function render(support:RenderSupport, alpha:Float):Void
	{
		if (mNumParticles == 0) return;
		
		// always call this method when you write custom rendering code!
		// it causes all previously batched quads/images to render.
		support.finishQuadBatch();
		
		// make this call to keep the statistics display in sync.
		// to play it safe, it's done in a backwards-compatible way here.
		
		if (Reflect.hasField(support, "raiseDrawCount")) {
			var raiseDrawCount:Function = Reflect.getProperty(support, "raiseDrawCount");
			Reflect.callMethod(support, raiseDrawCount, null);
		}
		
		alpha *= this.alpha;
		
		var context:Context3D = Starling.Context;
		var pma:Bool = texture.premultipliedAlpha;
		
		sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = pma ? alpha : 1.0;
		sRenderAlpha[3] = alpha;
		
		if (context == null) throw new MissingContextError();
		
		mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mNumParticles * 4);
		mIndexBuffer.uploadFromVector(mIndices, 0, mNumParticles * 6);
		
		context.setBlendFactors(mBlendFactorSource, mBlendFactorDestination);
		context.setTextureAt(0, mTexture.base);
		
		context.setProgram(mProgram);
		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
		context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, sRenderAlpha, 1);
		context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2); 
		context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_4);
		context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
		
		context.drawTriangles(mIndexBuffer, 0, mNumParticles * 2);
		
		context.setTextureAt(0, null);
		context.setVertexBufferAt(0, null);
		context.setVertexBufferAt(1, null);
		context.setVertexBufferAt(2, null);
	}
	
	/** Initialize the <tt>ParticleSystem</tt> with particles distributed randomly throughout
	 *  their lifespans. */
	public function populate(count:Int):Void
	{
		count = cast Math.min(count, mMaxCapacity - mNumParticles);
		
		if (mNumParticles + count > capacity)
			raiseCapacity(mNumParticles + count - capacity);
		
		var p:Particle;
		for (i in 0...count)
		{
			p = mParticles[mNumParticles+i];
			initParticle(p);
			advanceParticle(p, Math.random() * p.totalTime);
		}
		
		mNumParticles += count;
	}
	
	// program management
	
	private function createProgram():Void
	{
		var mipmap:Bool = mTexture.mipMapping;
		var textureFormat:Context3DTextureFormat = mTexture.format;
		var programName:String = "ext.ParticleSystem." + textureFormat + "/" +
								 mSmoothing.charAt(0) + (mipmap ? "+mm" : "");
		
		mProgram = Starling.current.getProgram(programName);
		
		
		
		
		if (mProgram == null)
		{
			
			
			var textureOptions:String =
				RenderSupport.getTextureLookupFlags(textureFormat, mipmap, false, mSmoothing);
			
			var vertexProgramCode:String =
				"m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clipspace
				"mul v0, va1, vc4 \n" + // multiply color with alpha and pass to fragment program
				"mov v1, va2      \n";  // pass texture coordinates to fragment program
			
			var fragmentProgramCode:String =
				"tex ft1, v1, fs0 " + textureOptions + "\n" + // sample texture 0
				"mul oc, ft1, v0";                            // multiply color with texel color
			
			//var assembler:AGALMiniAssembler = new AGALMiniAssembler();
			var vertexByteCode = AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, vertexProgramCode);
			var fragmentByteCode = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentProgramCode);
			
			mProgram = Starling.Context.createProgram();
			mProgram.upload(vertexByteCode, fragmentByteCode);
			
			//target.registerProgramFromSource(PROGRAM_NAME, vertexShader, fragmentShader);
			
			//Starling.current.registerProgramFromSource(programName, vertexProgramCode, fragmentProgramCode);
			//Starling.current.registerProgram(programName, vertexGLShader, fragmentGLShader);
			/*Starling.current.registerProgram(programName,
				assembler.assemble(cast Context3DProgramType.VERTEX, vertexProgramCode),
				assembler.assemble(cast Context3DProgramType.FRAGMENT, fragmentProgramCode));*/
			
			//mProgram = Starling.current.getProgram(programName);
			
			
			trace("FIX: " + mProgram);
			/*Starling.current.registerProgram(programName,
				assembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode),
				assembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode));*/
			
			
			//mProgram = Starling.current.getProgram(programName);
			//trace("mProgram = " + mProgram);
			
		}
	}
	
	public function get_isEmitting():Bool { return mEmissionTime > 0 && mEmissionRate > 0; }
	public function get_capacity():Int { return cast mVertexData.numVertices / 4; }
	public function get_numParticles():Int { return mNumParticles; }
	
	public function get_maxCapacity():Int { return mMaxCapacity; }
	public function set_maxCapacity(value:Int):Int
	{
		mMaxCapacity = cast Math.min(MAX_NUM_PARTICLES, value);
		return value;
	}
	
	public function get_emissionRate():Float { return mEmissionRate; }
	public function set_emissionRate(value:Float):Float { return mEmissionRate = value; }
	
	public function get_emitterX():Float { return mEmitterX; }
	public function set_emitterX(value:Float):Float { return mEmitterX = value; }
	
	public function get_emitterY():Float { return mEmitterY; }
	public function set_emitterY(value:Float):Float { return mEmitterY = value; }
	
	public function get_blendFactorSource():Context3DBlendFactor { return mBlendFactorSource; }
	public function set_blendFactorSource(value:Context3DBlendFactor):Context3DBlendFactor
	{
		mBlendFactorSource = value;
		updatePremultipliedAlpha();
		return value;
	}
	
	public function get_blendFactorDestination():Context3DBlendFactor { return mBlendFactorDestination; }
	public function set_blendFactorDestination(value:Context3DBlendFactor):Context3DBlendFactor
	{
		mBlendFactorDestination = value;
		updatePremultipliedAlpha();
		return value;
	}
	
	public function get_texture():Texture { return mTexture; }
	public function set_texture(value:Texture):Texture
	{
		if (value == null) throw new ArgumentError("Texture cannot be null");

		mTexture = value;
		createProgram();
		updatePremultipliedAlpha();
		
		var i = mVertexData.numVertices - 4;
		while (i >= 0) 
		{
			mVertexData.setTexCoords(i + 0, 0.0, 0.0);
			mVertexData.setTexCoords(i + 1, 1.0, 0.0);
			mVertexData.setTexCoords(i + 2, 0.0, 1.0);
			mVertexData.setTexCoords(i + 3, 1.0, 1.0);
			mTexture.adjustVertexData(mVertexData, i, 4);
			i -= 4;
		}
		return value;
	}
	
	public function get_smoothing():String { return mSmoothing; }
	public function set_smoothing(value:String):String { return mSmoothing = value; }
}