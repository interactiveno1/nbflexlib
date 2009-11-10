package com.nbilyk.effects.effectclasses {
	import com.nbilyk.effects.bitmaptransitions.BitmapTransition;
	import com.nbilyk.effects.bitmaptransitions.BitmapWipeTransition;
	
	import flash.display.DisplayObject;
	
	public class BitmapWipeEffectInstance extends BitmapEffectInstance {
		
		private var _direction:String;

		public function BitmapWipeEffectInstance(target:Object) {
			super(target);
		}
		override protected function createTransition(target:DisplayObject):BitmapTransition {
			var bitmapWipeTransition:BitmapWipeTransition = new BitmapWipeTransition(target, direction);
			return bitmapWipeTransition;
		}
		public function get direction():String {
			return _direction;
		}
		public function set direction(value:String):void {
			_direction = value;
			if (bitmapTransition) BitmapWipeTransition(bitmapTransition).direction = value;
		}
	}
}