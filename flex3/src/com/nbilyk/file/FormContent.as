package com.nbilyk.file {
	import flash.utils.ByteArray;

	public class FormContent {
		
		public var contentDisposition:String = "form-data";
		public var name:String;
		public var fileName:String;
		
		public var contentType:String;
		
		public var contents:ByteArray;
		
		public function FormContent(nameVal:String = "", contentsVal:ByteArray = null, fileNameVal:String = null, contentTypeVal:String = null) {
			name = nameVal;
			contents = contentsVal;
			fileName = fileNameVal;
			contentType = contentTypeVal;
		}
		
		/**
		 * Given a simple object of name=>value pairs, this utility method 
		 * returns a Vector of FormContent objects to represent the simple data parameters.
		 */
		public static function convertVariablesToFormContents(data:Object):Vector.<FormContent> {
			var v:Vector.<FormContent> = new Vector.<FormContent>();
			for (var all:String in data) {
				var formContent:FormContent = new FormContent();
				formContent.name = all;
				var bA:ByteArray = new ByteArray();
				bA.writeUTFBytes(String(data[all]));
				formContent.contents = bA;
				v.push(formContent);
			}
			return v;
		}
		
		/**
		 * Given a simple object of name=>value pairs, this utility method 
		 * returns a Vector of FormContent objects to represent the simple data parameters.
		 */
		public static function createFromVariable(name:String, value:String):FormContent {
			var f:FormContent = new FormContent();
			f.name = name;
			var bA:ByteArray = new ByteArray();
			bA.writeUTFBytes(value);
			f.contents = bA;
			return f;
		}
	}
}