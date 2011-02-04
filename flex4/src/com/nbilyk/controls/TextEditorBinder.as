package com.nbilyk.controls {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.text.engine.FontPosture;
	import flash.text.engine.FontWeight;
	
	import flashx.textLayout.events.SelectionEvent;
	import flashx.textLayout.formats.TextDecoration;
	import flashx.textLayout.formats.TextLayoutFormat;
	
	import spark.components.TextArea;

	[Event(name="formattingChange", type="flash.events.Event")]
	public class TextEditorBinder extends EventDispatcher {

		private var currentFormat:TextLayoutFormat = new TextLayoutFormat();
		
		private var _textEditor:TextArea;

		public function TextEditorBinder(target:IEventDispatcher = null) {
			super(target);
		}
		
		/**
		 * The TextFlow object to watch and apply styles.
		 */
		public function get textEditor():TextArea {
			return _textEditor;
		}
		
		public function set textEditor(value:TextArea):void {
			if (_textEditor == value)
				return; // no-op
			if (_textEditor) {
				_textEditor.removeEventListener(SelectionEvent.SELECTION_CHANGE, selectionChangeHandler);
			}
			_textEditor = value;
			if (_textEditor) {
				_textEditor.addEventListener(SelectionEvent.SELECTION_CHANGE, selectionChangeHandler);
			}
		}
		
		private function selectionChangeHandler(event:Event):void {
			refreshTextLayoutFormatProperties();
		}
		
		protected function refreshTextLayoutFormatProperties():void {
			if (textEditor) {
				currentFormat = textEditor.getFormatOfRange(new <String>["fontWeight", "fontStyle", "textDecoration"]);
			} else {
				currentFormat = new TextLayoutFormat();
			}
			dispatchEvent(new Event("formattingChange"));
		}
		
		protected function updateTextLayoutFormatProperties():void {
			if (!textEditor || !currentFormat) return;
			textEditor.setFormatOfRange(currentFormat);
			textEditor.setFocus();
			dispatchEvent(new Event("formattingChange"));
		}
		

		/**
		 * True if the current selection is bold.
		 */
		[Bindable("formattingChange")]
		public function get isBold():Boolean {
			return currentFormat.fontWeight == FontWeight.BOLD;
		}

		public function set isBold(value:Boolean):void {
			currentFormat.fontWeight = value ? FontWeight.BOLD : FontWeight.NORMAL;
			updateTextLayoutFormatProperties();
		}

		[Bindable("formattingChange")]
		public function get isItalic():Boolean {
			return currentFormat.fontStyle == FontPosture.ITALIC;
		}

		public function set isItalic(value:Boolean):void {
			currentFormat.fontStyle = value ? FontPosture.ITALIC : FontPosture.NORMAL;
			updateTextLayoutFormatProperties();
		}

		[Bindable("formattingChange")]
		public function get isUnderlined():Boolean {
			return currentFormat.textDecoration == TextDecoration.UNDERLINE;
		}

		public function set isUnderlined(value:Boolean):void {
			currentFormat.textDecoration = value ? TextDecoration.UNDERLINE : TextDecoration.NONE;
			updateTextLayoutFormatProperties();
		}
	}
}