package com.nbilyk.effects {
	import com.nbilyk.effects.bitmaptransitions.BitmapTransition;
	
	import flash.display.DisplayObject;
	
	import mx.core.mx_internal;
	import mx.effects.TweenEffect;
	import mx.effects.effectClasses.PropertyChanges;

	public class BitmapEffect extends TweenEffect {

		public function BitmapEffect() {
			super();
			if (className == "BitmapEffect") throw new Error("BitmapEffect is abstract.");
		}
		override public function captureStartValues():void {
			super.captureStartValues();
			if (targets.length > 0) {
				// Reset the PropertyChanges array.
				var newPropertyChangesArray:Array = [];

				// Create a new PropertyChanges object for the sum of all targets.
				for each (var target:Object in targets) {
					if (!(target is DisplayObject)) continue;
					var propertyChanges:PropertyChanges = new PropertyChanges(target);
					propertyChanges.start.beforeSnapshot = BitmapTransition.takeSnapshot(DisplayObject(target));
					newPropertyChangesArray.push(propertyChanges);
				}
				mx_internal::propertyChangesArray = newPropertyChangesArray;
			}
			endValuesCaptured = false;
		}
		override public function captureEndValues():void {
			captureStartValues();
		}
		
	}
}