package com.nbilyk.utils {
	import com.nbilyk.formatters.DateFormatter;
	
	import flash.utils.describeType;

	public class XMLUtils {
		
		/**
		 * Takes an XML Object [rawXml] and matches its properties with an Object [object]
		 */
		public static function autoMarshall(object:*, rawXml:XML):void {
			var typeXml:XML = describeType(object);
			for each (var variable:XML in typeXml.variable) {
				if (rawXml.hasOwnProperty(variable.@name)) {
					object[variable.@name] = parseString(rawXml[variable.@name], variable.@type);
				}
			}
			for each (var accessor:XML in typeXml.accessor) {
				if (accessor.@access == "readwrite") {
					if (rawXml.hasOwnProperty(accessor.@name)) {
						object[accessor.@name] = parseString(rawXml[accessor.@name], accessor.@type);
					}
				}
			}
		}
		
		/**
		 * Takes a string value and converts it based on the type parameter and returns that converted value.
		 */
		public static function parseString(value:String, type:String):* {
			switch (type) {
				case ("String") :
					return value;
				case ("Boolean") :
					return value.toLowerCase() == "true";
				case ("Number") :
					return parseFloat(value);
				case ("int") :
				case ("uint") :
					return parseInt(value);
				case ("Date") :
					return DateFormatter.parseDateString(value);
			}
		}
	}
}