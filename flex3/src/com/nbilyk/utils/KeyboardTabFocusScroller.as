package com.nbilyk.utils {
	import flash.events.FocusEvent;
	
	import mx.core.UIComponent;
	

	public class KeyboardTabFocusScroller {
		
		private var target:UIComponent;
		
		public function KeyboardTabFocusScroller(targetVal:UIComponent) {
			target = targetVal;
			target.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, keyFocusChangeHandler, false, 0, true);
		}
		
		private function keyFocusChangeHandler(event:FocusEvent):void {
			//trace(event.target);
		}
		
		public function destroy():void {
			target.removeEventListener(FocusEvent.KEY_FOCUS_CHANGE, keyFocusChangeHandler);
			target = null;
		}

	}
}