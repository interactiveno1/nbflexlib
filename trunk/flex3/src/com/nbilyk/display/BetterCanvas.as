package com.nbilyk.display {
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;

	public class BetterCanvas extends Canvas {
		
		public function BetterCanvas() {
			super();
			verticalScrollPolicy = ScrollPolicy.OFF;
			horizontalScrollPolicy = ScrollPolicy.OFF;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (whiteBox && whiteBox.alpha) whiteBox.alpha = 0;
			
			var hasChanged:Boolean;
			if (unscaledHeight < measuredHeight) {
				if (verticalScrollPolicy != ScrollPolicy.ON) {
					verticalScrollPolicy = ScrollPolicy.ON;
					hasChanged = true;
				}
			} else {
				if (verticalScrollPolicy != ScrollPolicy.OFF) {
					verticalScrollPolicy = ScrollPolicy.OFF;
					hasChanged = true;
				}
			}
			if (unscaledWidth < measuredWidth) {
				if (horizontalScrollPolicy != ScrollPolicy.ON) {
					horizontalScrollPolicy = ScrollPolicy.ON;
					hasChanged = true;
				}
				
			} else {
				if (horizontalScrollPolicy != ScrollPolicy.OFF) {
					horizontalScrollPolicy = ScrollPolicy.OFF;
					hasChanged = true;
				}
			}
			if (hasChanged) super.updateDisplayList(unscaledWidth, unscaledHeight);
			
		}
		/*
		override public function set verticalScrollPolicy(value:String):void {
			if (!internalSet) originalVerticalScrollPolicy = value;
			super.verticalScrollPolicy = value;
		}
		
		protected function setVerticalScrollPolicy(newPolicy:String):void {
			internalSet = true;
			verticalScrollPolicy = newPolicy;
			internalSet = false;
		}*/
	}
}