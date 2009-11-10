package com.nbilyk.formatters {
	import mx.formatters.Formatter;
	import mx.formatters.NumberBase;
	import mx.formatters.NumberFormatter;

	public class FileSizeFormatter extends NumberFormatter {
		
		public function FileSizeFormatter() {
			super();
			precision = 2;
		}
		
		/**
		 * Formats a number in bytes to a string in the form of:
		 * 3.42 MB
		 * 2.00 KB
		 * 12.34 GB
		 */
		override public function format(value:Object):String {
			if (!(value is Number)) {
				var dataFormatter:NumberBase = new NumberBase();
				value = dataFormatter.parseNumberString(value.toString());
			}
			var v:Number = Number(value);
			if (isNaN(v)) {
				error = Formatter.defaultInvalidFormatError;
            	return "";
			}
			
			var strlen:uint = v.toString().length;
			var s:String;
			if (strlen >= 7 && strlen < 10) { 
				s = super.format(v / 1048576); 
				return s + " MB"; 
			} else if (strlen >= 10) { 
				s = super.format(v / 1073741824); 
				return s + " GB"; 
			} else { 
				s = super.format(v / 1024); 
				return s + " KB"; 
			}
		}

	}
}