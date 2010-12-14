package com.nbilyk.history {
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class HistoryTracker extends EventDispatcher {
		private var _currentHistoryIndex:int = 0;

		private var history:Array = [];

		[Bindable]
		private var historyLength:uint;

		private var changingHistoryIndex:Boolean;
		private var maxHistoryLength:uint = 100;

		public function HistoryTracker(prettyHistoryManager:PrettyHistoryManager) {
			super();
			history.push(prettyHistoryManager.getAction());
			historyLength = 1;
			PrettyHistoryManager.instance.addEventListener(PrettyHistoryManager.ACTION_CHANGE, actionChangedHandler, false, 0, true);
		}

		private function actionChangedHandler(event:Event):void {
			if (changingHistoryIndex) return;
			var newFragment:String = PrettyHistoryManager.instance.getAction();
			history.length = currentHistoryIndex + 1;
			if (historyLength && history[historyLength - 1] == newFragment) return;
			// No change
			history.push(newFragment);
			if (history.length > maxHistoryLength) history.shift();
			historyLength = history.length;
			_currentHistoryIndex = historyLength - 1;
			dispatchEvent(new Event("currentHistoryIndexChange"));
		}

		[Bindable("currentHistoryIndexChange")]
		public function get currentHistoryIndex():int {
			return _currentHistoryIndex;
		}

		public function set currentHistoryIndex(value:int):void {
			if (!history.length) return;
			value = Math.max(0, Math.min(value, historyLength - 1));
			if (_currentHistoryIndex == value) return;
			changingHistoryIndex = true;
			_currentHistoryIndex = value;
			PrettyHistoryManager.instance.setFragment(history[value]);
			changingHistoryIndex = false;
			dispatchEvent(new Event("currentHistoryIndexChange"));
		}

		/**
		 * Finds the last recorded url that begins with the given action.
		 */
		public function findLastHistoryWithAction(action:String):String {
			var n:uint = history.length;
			while (n--) {
				if (PrettyHistoryManager.isActionAInActionB(action, history[n])) {
					return history[n];
				}
			}
			return null;
		}
	}
}