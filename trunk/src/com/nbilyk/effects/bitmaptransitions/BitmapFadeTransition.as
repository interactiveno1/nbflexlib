package com.nbilyk.effects.bitmaptransitions {
	import flash.display.DisplayObject;

	public class BitmapFadeTransition extends BitmapTransition {
		public function BitmapFadeTransition(targetVal:DisplayObject) {
			super(targetVal);
		}
		
		override protected function tweenStart():void {
			if (!beforeSnapshot || !afterSnapshot) return;
			beforeSnapshot.alpha = 1;
			afterSnapshot.alpha = 0;
		}
		override protected function tweenUpdate(value:Number):void {
			if (afterSnapshot) afterSnapshot.alpha = value;
			if (!endIsVisible && beforeSnapshot) beforeSnapshot.alpha = 1 - value; 
		}
	}
}