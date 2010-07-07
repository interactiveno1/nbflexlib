package com.nbilyk.controls {
	import flashx.textLayout.conversion.TextConverter;
	
	import spark.components.RichText;

	public class RichHtmlText extends RichText {
		
		private var _htmlText:String;
		
		public function RichHtmlText() {
			super();
		}


		public function get htmlText():String {
			return _htmlText;
		}

		public function set htmlText(value:String):void {
			_htmlText = value;
			textFlow = TextConverter.importToFlow(value, TextConverter.TEXT_FIELD_HTML_FORMAT);
		}

	}
}