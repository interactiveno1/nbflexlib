/**
 * Copyright (c) 2009 Nicholas Bilyk
 */
package com.nbilyk.effects.bitmaptransitions {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.effects.Tween;
	import mx.events.EffectEvent;
	import mx.events.TweenEvent;
	
	/**
	 * This class is the base class for transitions that involve capturing two bitmap shots and transitioning between them.
	 * If you are intending to use this as a Flex effect, consider using one of the Effect wrappers such as SmoothFadeEffect.
	 */
	[Event(name="effectStart", type="mx.events.EffectEvent")]
	[Event(name="effectEnd", type="mx.events.EffectEvent")]
	public class BitmapTransition extends EventDispatcher {
		public var beforeSnapshot:Sprite;
		public var afterSnapshot:Sprite;
		private var _target:DisplayObject;
		protected var targetParent:Object; // Either IChildList or DisplayObjectContainer
		protected var endIsVisible:Boolean;
		public var duration:Number = 1000;
		public var easingFunction:Function;
		
		public function BitmapTransition(targetVal:DisplayObject) {
			target = targetVal;
		}
		
		/**
		 * Creates a bitmap of the target DisplayObject and then applies any needed transformations on it.
		 */
		public static function takeSnapshot(target:DisplayObject):Sprite {
			var bounds:Rectangle = target.getBounds(target);
			var bmpd:BitmapData = new BitmapData(bounds.width, bounds.height, true, 0x00000000);
			var mat:Matrix = new Matrix();
			mat.translate(-bounds.left, -bounds.top);
			if (target.visible) bmpd.draw(target, mat);
			
			var bmp:Bitmap = new Bitmap(bmpd, PixelSnapping.AUTO, true);
			bmp.x = bounds.left;
			bmp.y = bounds.top;
			var s:Sprite = new Sprite();
			s.transform.matrix = target.transform.matrix;
			s.addChild(bmp);
			
			return s;
		}
		
		public function get target():DisplayObject {
			return _target;
		}
		public function set target(value:DisplayObject):void {
			if (!value.parent) throw new Error("target must be parented.");
			_target = value;
			if (value.parent is Container) {
				targetParent = Container(value.parent).rawChildren;
			} else {
				targetParent = value.parent;
			}
		}
		
		/**
		 * Sets the beforeSnapshot property.  This must be done prior to calling start().
		 */
		public function takeBeforeSnapshot():void {
			beforeSnapshot = takeSnapshot(target);
		}
		protected function prepareForTransition():void {
			if (target is UIComponent) {
				UIComponent(target).validateNow();
				UIComponent(target).validateDisplayList();
			}
			afterSnapshot = takeSnapshot(target);
			targetParent.addChild(beforeSnapshot);
			targetParent.addChild(afterSnapshot);
			endIsVisible = target.visible;
			target.visible = false;
		}
		
		/**
		 * Starts the transition. Make sure that beforeSnapshot is set before starting.  
		 * You can use takeBeforeSnapshot(), or manually set it via the property beforeSnapshot
		 */
		public function start():Tween {
			if (!beforeSnapshot) throw new Error("You must call takeBeforeSnapshot() before you call start()");
			prepareForTransition();
			tweenStart();
			var tween:Tween = new Tween(this, 0, 1, duration, -1, tweenUpdate, tweenEnd);
			tween.addEventListener(TweenEvent.TWEEN_END, tweenEndHandler);
			if (easingFunction != null) tween.easingFunction = easingFunction;
			dispatchEvent(new EffectEvent(EffectEvent.EFFECT_START));
			return tween;
		}
		
		/**
		 * Override this method if you want to change from a simple fade transition
		 */
		[Abstract]
		protected function tweenStart():void {
		}
		/**
		 * Override this method if you want to change from a simple fade transition
		 */
		[Abstract]
		protected function tweenUpdate(value:Number):void {
		}
		
		protected function tweenEnd(value:Number):void {
			if (!beforeSnapshot || !afterSnapshot) return;
			target.visible = endIsVisible;
			if (beforeSnapshot.parent) targetParent.removeChild(beforeSnapshot);
			if (afterSnapshot.parent) targetParent.removeChild(afterSnapshot);
			beforeSnapshot = null;
			afterSnapshot = null;
			
			dispatchEvent(new EffectEvent(EffectEvent.EFFECT_END));
		}
		protected function tweenEndHandler(event:TweenEvent):void {
			IEventDispatcher(event.currentTarget).removeEventListener(event.type, tweenEndHandler);
			
		}
		

	}
}