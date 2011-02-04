package com.nbilyk.utils {
	import flash.text.engine.FontWeight;
	
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.formats.TextLayoutFormat;

	public class TextFlowUtils {

		/**
		 * Uses the TextConverter to convert a textFlow to html.
		 *
		 * @var textFlow The TextFlow object to conver to html
		 * @var clean If true, the
		 */
		public static function toHtmlText(textFlow:TextFlow, clean:Boolean = true):String {
			var tF:TextFlow;
			if (clean) {
				cleanFlowGroup(textFlow);
				tF = textFlow;
			} else {
				tF = textFlow;
			}
			return TextConverter.export(tF, TextConverter.TEXT_FIELD_HTML_FORMAT, ConversionType.STRING_TYPE) as String;
		}

		private static function cleanFlowGroup(flowElement:FlowElement, depth:int = 0):void {
			var tb:String = "";
			for (var i:uint = 0; i < depth; i++) {
				tb += " ";
			}
			flowElement.clearStyle("fontFamily");
			if (flowElement is FlowGroupElement) {
				var flowGroupElement:FlowGroupElement = FlowGroupElement(flowElement);
				var n:uint = flowGroupElement.numChildren;
				for (var j:uint = 0; j < n; j++) {
					cleanFlowGroup(flowGroupElement.getChildAt(j), depth + 1);
				}
			}
		}
		
		public static function toXml(textFlow:TextFlow):String {
			return TextConverter.export(textFlow, TextConverter.TEXT_LAYOUT_FORMAT, ConversionType.XML_TYPE) as XML;
		}

		/**
		 * Uses the TextConverter to convert html to a TextFlow object.
		 */
		public static function fromHtmlText(value:String):TextFlow {
			var html:String = value;
			html = html.replace(/<strong>/gi, "<b>");
			html = html.replace(/<\/strong>/gi, "</b>");
			html = html.replace(/<em>/gi, "<i>");
			html = html.replace(/<\/em>/gi, "</i>");

			return TextConverter.importToFlow(html, TextConverter.TEXT_FIELD_HTML_FORMAT);
		}
	}
}