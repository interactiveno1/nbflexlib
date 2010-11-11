package com.nbilyk.controls {
	import flash.utils.describeType;
	
	import mx.core.FlexGlobals;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IStyleManager2;
	import mx.styles.StyleManager;

	public class CSSComponent extends CSSStyleDeclaration {

		private var _styleName:String;
		private var classInheritance:Array;

		public function CSSComponent(selector:String = null) {
			super(selector);

			classInheritance = new Array();
			var descriptionXml:XML = describeType(this);
			classInheritance.push(descriptionXml.@name.split("::").pop());
			for each (var xml:XML in descriptionXml.extendsClass) {
				var fullClassName:String = xml.@type;
				var className:String = fullClassName.split("::").pop();
				if (className == "CSSComponent") break;
				classInheritance.push(className);
			}
		}

		public function get styleName():String {
			return _styleName;
		}
		public function set styleName(value:String):void {
			_styleName = value;
		}

		override public function getStyle(styleProp:String):* {
			var styleManager:IStyleManager2 = FlexGlobals.topLevelApplication.styleManager;
			var style:* = super.getStyle(styleProp);
			if (style) return style;
			if (styleName) {
				css = styleManager.getStyleDeclaration("." + styleName);
				if (css) return css.getStyle(styleProp);
			}
			for each (var c:String in classInheritance) {
				var css:CSSStyleDeclaration = styleManager.getStyleDeclaration(c);
				if (css) {
					style = css.getStyle(styleProp);
					if (style) return style;
				}
			}
			return null;
		}
	}
}