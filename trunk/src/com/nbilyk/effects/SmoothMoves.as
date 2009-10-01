package com.nbilyk.effects {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.effects.Tween;
	import mx.events.TweenEvent;
	
	public class SmoothMoves extends EventDispatcher {
		public static const FADE:String = "fade";
		
		private var beforeSnapshot:Bitmap;
		private var afterSnapshot:Bitmap;
		private var _target:DisplayObject;
		
		public function SmoothMoves(targetVal:DisplayObject) {
			target = targetVal;
		}
		
		public function get target():DisplayObject {
			return _target;
		}
		public function set target(value:DisplayObject):void {
			_target = value;
		}
		
		private function get stage():Stage {
			return Application(Application.application).stage;
		}
		
		public function takeBeforeSnapshot():void {
			beforeSnapshot = takeSnapshot();
			beforeSnapshot.transform.matrix = target.transform.concatenatedMatrix.clone();
		}
		protected function takeSnapshot():Bitmap {
			var bmpd:BitmapData = new BitmapData(target.width, target.height);
			bmpd.draw(target);
			return new Bitmap(bmpd, PixelSnapping.AUTO, true);
		}
		
		protected function prepareForTransition():void {
			if (target is UIComponent) {
				UIComponent(target).validateNow();
				UIComponent(target).validateDisplayList();
			}
			afterSnapshot = takeSnapshot();
			afterSnapshot.transform.matrix = target.transform.concatenatedMatrix.clone();
			stage.addChild(beforeSnapshot);
			stage.addChild(afterSnapshot);
			target.visible = false;
		}
		public function start():Tween {
			if (!beforeSnapshot) throw new Error("You must call takeBeforeSnapshot() before you call start()");
			prepareForTransition();
			tweenStart();
			return new Tween(this, 0, 1, 1000, -1, tweenUpdate, tweenEnd);
		}
		
		protected function tweenStart():void {
			beforeSnapshot.alpha = 1;
			afterSnapshot.alpha = 0;
		}
		protected function tweenUpdate(value:Number):void {
			if (afterSnapshot) afterSnapshot.alpha = value;
		}
		protected function tweenEnd(value:Number):void {
			target.visible = true;
			if (beforeSnapshot.parent) beforeSnapshot.parent.removeChild(beforeSnapshot);
			if (afterSnapshot.parent) afterSnapshot.parent.removeChild(afterSnapshot);
			beforeSnapshot.bitmapData.dispose();
			afterSnapshot.bitmapData.dispose();
			beforeSnapshot = null;
			afterSnapshot = null;
		}
		

	}
}