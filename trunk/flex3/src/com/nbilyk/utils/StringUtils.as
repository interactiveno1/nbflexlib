/**
 * Copyright (c) 2006 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.display.DisplayObject;
	
	public class StringUtils {
		
		public static function stringToObject(str:String, scope:DisplayObject):Object {
			// Throws an error if _str does not path correctly to a DisplayObject
			var arr:Array = str.split(".");
			var obj:DisplayObject;
			if (arr[0] == "this") {
				obj = scope;
				arr.splice(0, 1);
			} else {
				obj = scope.root;
			}
			var len:int = arr.length;
			for (var i:int = 0; i<len; i++) {
				obj = obj[arr[i]];
			}
			return obj;
		}
		public static function replaceSubStr(str:String, find:String, replace:String):String {
			var split:Array = str.split(find);
			return split.join(replace);
		}
		public static function replaceSubStrs(str:String, find:Array, replace:Array):String {
			var newStr:String = str;
			var findL:uint = find.length;
			if (findL != replace.length) throw new ArgumentError("The find array length does not match the replace array length.");
			for (var i:uint = 0; i < findL; i++) {
				newStr = replaceSubStr(newStr, find[i], replace[i]);
			}
			return newStr;
		}
		
		public static function trim(str:String):String {
			if (!str) return str;
			return ltrim(rtrim(str));
		}
		public static function rtrim(str:String):String {
			var i:int = str.length - 1;
			var char:String = str.charAt(i);
			while (i > 0 && (char == " " || char == String.fromCharCode(10) || char == String.fromCharCode(13) || char == String.fromCharCode(9))) {
				i--;
				char = str.charAt(i);
			}
			return str.substring(0, i + 1);
		}	
		public static function ltrim(str:String):String {
			var i:int = 0;
			var char:String = str.charAt(i);
			while (i < str.length && (char == " " || char == String.fromCharCode(10) || char == String.fromCharCode(13) || char == String.fromCharCode(9))) {
				i++;
				char = str.charAt(i);
			}		
			return str.substring(i, str.length);
		}
		public static function getFileExtension(filename:String):String {
			var i:int = filename.lastIndexOf(".");
			if (i == -1) return "";
			return filename.substr(i + 1).toLowerCase();
		}
		public static function validEmail(email:String):Boolean {
			var a:int = email.indexOf("@");
			if (a == email.lastIndexOf("@")) {
				if (a > 0) {
					if (email.lastIndexOf(".") > a) {
						return true;
					}
				}
			}
			return false;
		}
		public static function seo(str:String):String {
			var pattern:RegExp = /[^a-z0-9]+/ig;
			return str.replace(pattern, "-");
		}
		public static function xmlNodeToHTMLString(xml:XML):String {
			var _str:String = "";
			var children:XMLList = xml.children();
			for each (var child:XML in children) {
				_str += StringUtils.trim(child.toXMLString());
			}
			return _str;
		}
		
		
		/**
		 *  Taken from Adobe's HistoryManagerImpl. I think this function should really be in a utility class. 
		 * 
		 *  Function to calculate a cyclic rendundancy checksum (CRC).
		 *  This returns a 4-character hex string representing a 16-bit uint
		 *  calculated from the specified string using the CRC-CCITT mask.
		 *  In http://www.joegeluso.com/software/articles/ccitt.htm,
		 *  the following sample input and output is given to check
		 *  this implementation:
		 *  "" -> "1D0F"
		 *  "A" -> "9479"
		 *  "123456789" -> "E5CC"
		 *  "AA...A" (256 A's) ->"E938"
		 */
		public static function calcCrc(s:String):String {
			var crc:uint = 0xFFFF;

			// Process each character in the string.
			var n:int = s.length;
			for (var i:int = 0; i < n; i++) {
				var charCode:uint = s.charCodeAt(i);

				// Unicode characters can be greater than 255.
				// If so, we let both bytes contribute to the CRC.
				// If not, we let only the low byte contribute.
				var loByte:uint = charCode & 0x00FF;
				var hiByte:uint = charCode >> 8;
				if (hiByte != 0)
					crc = updateCrc(crc, hiByte);
				crc = updateCrc(crc, loByte);
			}

			// Process 2 additional zero bytes, as specified by the CCITT algorithm.
			crc = updateCrc(crc, 0);
			crc = updateCrc(crc, 0);

			return crc.toString(16);
		}
		private static function updateCrc(crc:uint, byte:uint):uint {
			const poly:uint = 0x1021; // CRC-CCITT mask

			var bitMask:uint = 0x80;

			// Process each bit in the byte.
			for (var i:int = 0; i < 8; i++) {
				var xorFlag:Boolean = (crc & 0x8000) != 0;

				crc <<= 1;
				crc &= 0xFFFF;

				if ((byte & bitMask) != 0)
					crc++;

				if (xorFlag)
					crc ^= poly;

				bitMask >>= 1;
			}

			return crc;
		}
		
	}
}