package com.nbilyk.effects {
	import com.nbilyk.effects.effectclasses.BitmapWipeEffectInstance;
	
	import mx.effects.IEffectInstance;

	public class BitmapWipeEffect extends BitmapEffect {
		public static const LEFT:String = "left";
		public static const UP:String = "up";
		public static const RIGHT:String = "right";
		public static const DOWN:String = "down";
		
		[Inspectable(defaultValue="left", enumeration="left,up,right,down")]
		public var direction:String = LEFT;
		
		public function BitmapWipeEffect() {
			super();
			instanceClass = BitmapWipeEffectInstance;
		}

		override protected function initInstance(instance:IEffectInstance):void {
			super.initInstance(instance);

			var bitmapWipeEffectInstance:BitmapWipeEffectInstance = BitmapWipeEffectInstance(instance);
			bitmapWipeEffectInstance.direction = direction;
		}
	}
}