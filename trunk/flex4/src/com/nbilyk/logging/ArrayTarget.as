package com.nbilyk.logging {
	import mx.core.mx_internal;
	import mx.logging.targets.LineFormattedTarget;

	use namespace mx_internal;

	public class ArrayTarget extends LineFormattedTarget {

		private static const MAX_LENGTH:uint = 1500;

		private var _arr:Array;

		public function ArrayTarget() {
			super();
			_arr = new Array();
		}

		override mx_internal function internalLog(message:String):void {
			_arr.push(message);
			if (_arr.length > MAX_LENGTH)
				_arr.shift();
		}

		public function get text():String {
			return _arr.join("\n");
		}

		public function get logs():Array {
			return _arr;
		}

		public function clear():void {
			_arr = new Array();
		}
	}
}