package com.nbilyk.utils {
	import mx.formatters.DateFormatter;
	
	public class ParsingUtil {
		public static function parseBoolean(value:String, defaultValue:Boolean = false):Boolean {
			if (value == null) return defaultValue;
			var v:String = value.toLowerCase();
			if (v == "true" || v == "1") return true;
			else if (v == "false" || v == "0") return false;
			return defaultValue;
		}
		public static function parseNumber(value:String, defaultValue:Number = 0):Number {
			if (value == null) return defaultValue;
			var val:Number = parseFloat(value);
			if (isNaN(val)) return defaultValue;
			else return val;
			return defaultValue;
		}
		public static function parseDate(value:String):Date {
			return DateFormatter.parseDateString(value);
		}
	}
}