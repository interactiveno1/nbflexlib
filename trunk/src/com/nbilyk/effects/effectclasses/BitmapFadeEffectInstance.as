package com.nbilyk.effects.effectclasses {
	import com.nbilyk.effects.bitmaptransitions.BitmapFadeTransition;
	import com.nbilyk.effects.bitmaptransitions.BitmapTransition;
	
	import flash.display.DisplayObject;
	
	public class BitmapFadeEffectInstance extends BitmapEffectInstance {
		public function BitmapFadeEffectInstance(target:Object) {
			super(target);
		}
		override protected function createTransition(target:DisplayObject):BitmapTransition {
			return new BitmapFadeTransition(target);
		}
	}
}