package com.nbilyk.display {
	import mx.controls.Text;

	public class BetterText extends Text {
		public function BetterText() {
			super();
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (!unscaledHeight) validateSize(true);
		}

	}
}