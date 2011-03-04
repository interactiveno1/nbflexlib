package com.nbilyk.utils {
	import flashx.textLayout.container.TextContainerManager;
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.conversion.ITextImporter;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.Configuration;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;
	
	public class TextFlowUtils {

		/**
		 * Uses the TextConverter to convert a textFlow to html.
		 *
		 * @var textFlow The TextFlow object to conver to html
		 */
		public static function toHtmlText(textFlow:TextFlow, prettyPrinting:Boolean = false):String {
			var staticConfiguration:Configuration = Configuration(TextContainerManager.defaultConfiguration).clone();
			staticConfiguration.manageEnterKey = false; 
			staticConfiguration.manageTabKey = false;

			var staticPlainTextImporter:ITextImporter = TextConverter.getImporter(TextConverter.PLAIN_TEXT_FORMAT, staticConfiguration);
			var defaultFlow:TextFlow = staticPlainTextImporter.importToFlow("");
			var defaultFlowXml:XML = TextConverter.export(defaultFlow, TextConverter.TEXT_FIELD_HTML_FORMAT, ConversionType.XML_TYPE) as XML;
			defaultFlowXml = defaultFlowXml.BODY[0];
			var flowXml:XML = TextConverter.export(textFlow.deepCopy() as TextFlow, TextConverter.TEXT_FIELD_HTML_FORMAT, ConversionType.XML_TYPE) as XML;
			flowXml = flowXml.BODY[0];
			
			cleanFlowXml(flowXml, defaultFlowXml);
			return xmlToHtml(flowXml.children(), prettyPrinting);
		}
		
		private static function cleanFlowXml(flowXml:XML, defaultFlowXml:XML):void {
			for each (var descendant:XML in defaultFlowXml.descendants()) {
				for each (var flowDescendant:XML in flowXml.descendants(String(descendant.name()))) {
					for each (var attribute:XML in descendant.attributes()) {
						
						if (flowDescendant.attribute(String(attribute.name())) == attribute.toString()) {
							delete flowDescendant["@" + String(attribute.name())];
						}
					}
					if (flowDescendant.name() == "FONT" && flowDescendant.attributes().length() == 0) {
						XMLList(flowDescendant.parent()).insertChildAfter(flowDescendant, flowDescendant.children());
						delete flowDescendant.parent()[flowDescendant.name()];
					}
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

		/**
		 * Converts xml to html.
		 */
		private static function xmlToHtml(xml:XMLList, prettyPrinting:Boolean = false):String {
			var result:String;
			var originalSettings:Object = XML.settings();
			try {
				XML.ignoreProcessingInstructions = false;
				XML.ignoreWhitespace = false;
				XML.prettyPrinting = prettyPrinting;
				result = xml.toXMLString();
				XML.setSettings(originalSettings);
			} catch (e:Error) {
				XML.setSettings(originalSettings);
				throw(e);
			}
			return result;
		}
	}
}