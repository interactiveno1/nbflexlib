package com.nbilyk.display {
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;

	public class BetterCanvas extends Canvas {
		
		private var originalVerticalScrollPolicy:String;
		private var internalSet:Boolean;
		
		public function BetterCanvas() {
			super();
			originalVerticalScrollPolicy = verticalScrollPolicy;
			if (originalVerticalScrollPolicy == ScrollPolicy.AUTO) {
				setVerticalScrollPolicy(ScrollPolicy.OFF);
			}
		}
		
		override public function validateSize(recursive:Boolean = false):void {
			super.validateSize(recursive);
			if (originalVerticalScrollPolicy != ScrollPolicy.AUTO) return;
			if (!initialized) return;
			if (height < measuredHeight) setVerticalScrollPolicy(ScrollPolicy.ON);
			else setVerticalScrollPolicy(ScrollPolicy.OFF);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (whiteBox && whiteBox.alpha) whiteBox.alpha = 0;
		}
		
		override public function set verticalScrollPolicy(value:String):void {
			if (!internalSet) originalVerticalScrollPolicy = value;
			super.verticalScrollPolicy = value;
		}
		
		protected function setVerticalScrollPolicy(newPolicy:String):void {
			internalSet = true;
			verticalScrollPolicy = newPolicy;
			internalSet = false;
		}
	}
}