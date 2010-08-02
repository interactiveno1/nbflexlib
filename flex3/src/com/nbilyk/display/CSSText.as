package com.nbilyk.display {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	import flash.utils.ByteArray;

	[Style(name="styleSheetAsset", type="Class")]
	[Event(name="cssComplete", type="flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	public class CSSText extends BetterText {
		public static const CSS_COMPLETE:String = "cssComplete";

		private var _styleSheetUrl:String;

		public function CSSText() {
			super();
		}

		[Bindable]
		public function get styleSheetUrl():String {
			return _styleSheetUrl;
		}

		public function set styleSheetUrl(value:String):void {
			_styleSheetUrl = value;
			loadStyleSheet(value);
		}

		override public function stylesInitialized():void {
			super.stylesInitialized();
			var c:Class = getStyle("styleSheetAsset") as Class;
			if (c) {
				try {
					var ba:ByteArray = new c();
					ba.position = 0;
					var css:String = ba.readUTFBytes(ba.bytesAvailable);

					var newStyleSheet:StyleSheet = new StyleSheet();
					newStyleSheet.parseCSS(css);
					styleSheet = newStyleSheet;
				} catch (error:Error) {
					dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, error.message));
				}
			}
		}

		public function loadStyleSheet(url:String):void {
			var urlLoader:URLLoader = new URLLoader();
			var urlRequest:URLRequest = new URLRequest(url);
			urlLoader.addEventListener(Event.COMPLETE, styleSheetLoaderCompleteHandler, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, styleSheetIoErrorHandler, false, 0, true);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, styleSheetSecurityErrorHandler, false, 0, true);
			urlLoader.load(urlRequest);
		}

		private function styleSheetLoaderCompleteHandler(event:Event):void {
			var urlLoader:URLLoader = URLLoader(event.currentTarget);
			var newStyleSheet:StyleSheet = new StyleSheet();
			newStyleSheet.parseCSS(urlLoader.data);
			styleSheet = newStyleSheet;
			dispatchEvent(new Event(CSS_COMPLETE));
		}

		private function styleSheetIoErrorHandler(event:IOErrorEvent):void {
			dispatchEvent(event);
		}

		private function styleSheetSecurityErrorHandler(event:SecurityErrorEvent):void {
			dispatchEvent(event);
		}
	}
}