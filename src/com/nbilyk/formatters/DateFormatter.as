package com.nbilyk.formatters {
	import mx.formatters.DateFormatter;

	public class DateFormatter extends mx.formatters.DateFormatter {
		public function DateFormatter() {
			super();
		}
		public static function parseDateString(str:String):Date {
			return mx.formatters.DateFormatter.parseDateString(str);			
		}
	}
}