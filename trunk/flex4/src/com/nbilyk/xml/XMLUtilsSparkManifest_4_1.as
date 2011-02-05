package com.nbilyk.xml {

	public class XMLUtilsSparkManifest_4_1 {
		
		[Embed(source="/assets/xml/4.1/mxml-2009-manifest.xml", mimeType="application/octet-stream")]
		private static const FxManifest:Class;
		
		[Embed(source="/assets/xml/4.1/spark-manifest.xml", mimeType="application/octet-stream")]
		private static const SparkManifest:Class;
		
		[Embed(source="/assets/xml/4.1/mx-manifest.xml", mimeType="application/octet-stream")]
		private static const MxManifest:Class;
		
		public static function initialize():void {
			XMLUtils.parseManifest(XML(new FxManifest()), new Namespace("fx", "http://ns.adobe.com/mxml/2009"));
			XMLUtils.parseManifest(XML(new SparkManifest()), new Namespace("s", "library://ns.adobe.com/flex/spark"));
			XMLUtils.parseManifest(XML(new MxManifest()), new Namespace("mx", "library://ns.adobe.com/flex/mx"));
		}
	}
}