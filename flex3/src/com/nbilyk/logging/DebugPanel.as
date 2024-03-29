package com.nbilyk.logging {
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.TextArea;
	import mx.logging.Log;

	[ResourceBundle("nbflexlib")]
	public class DebugPanel extends VBox {
		
		protected var arrayTarget:ArrayTarget;
		
		// Stage instances
		protected var debugText:TextArea;
		protected var controlsContainer:HBox;
		protected var closeButton:Button;
		protected var clearButton:Button;
		protected var refreshButton:Button;
		
		// Validation properties
		private var labelsAreValidFlag:Boolean;
		private var logIsValid:Boolean = true;
		
		public function DebugPanel() {
			super();
			
			arrayTarget = new ArrayTarget();
			Log.addTarget(arrayTarget);
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler, false, 0, true);
			
			visible = false;
			includeInLayout = false;
		}
		
		private function addedToStageHandler(event:Event):void {
			stage.addEventListener(KeyboardEvent.KEY_DOWN, mainKeyDownHandler, false, 0, true);
		}
		
		private function removedFromStageHandler(event:Event):void {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, mainKeyDownHandler);
		}

		protected function mainKeyDownHandler(event:KeyboardEvent):void {
			if (event.ctrlKey && event.keyCode == Keyboard.F12) {
				// Ctrl + F12
				visible = !visible;
				if (visible)
					refreshLog();
			}
		}
		
		//----------------------------------
		// Validation / invalidation
		//----------------------------------
		
		override protected function resourcesChanged():void {
			super.resourcesChanged();
			invalidateLabels();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			debugText = new TextArea();
			debugText.percentWidth = 100;
			debugText.percentHeight = 100;
			addChild(debugText);
			
			controlsContainer = new HBox();
			
			closeButton = new Button();
			closeButton.addEventListener(MouseEvent.CLICK, closeClickHandler);
			controlsContainer.addChild(closeButton);
			
			clearButton = new Button();
			clearButton.addEventListener(MouseEvent.CLICK, clearClickHandler);
			controlsContainer.addChild(clearButton);
			
			refreshButton = new Button();
			refreshButton.addEventListener(MouseEvent.CLICK, refreshClickHandler);
			controlsContainer.addChild(refreshButton);
			
			addChild(controlsContainer);
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			if (!labelsAreValidFlag) validateLabels();
			if (!logIsValid) validateLog();
		}
		
		public function invalidateLabels():void {
			labelsAreValidFlag = false;
			invalidateProperties();
		}
		protected function validateLabels():void {
			labelsAreValidFlag = true;
			
			closeButton.label = resourceManager.getString("nbflexlib", "logger.close");
			clearButton.label = resourceManager.getString("nbflexlib", "logger.clearLog");
			refreshButton.label = resourceManager.getString("nbflexlib", "logger.refresh");
		}
		
		public function invalidateLog():void {
			logIsValid = false;
			invalidateProperties();
		}
		protected function validateLog():void {
			logIsValid = true;
			debugText.text = arrayTarget.text;
			debugText.validateNow();
			debugText.verticalScrollPosition = debugText.maxVerticalScrollPosition;
		}
		
		//----------------------------------
		// Control event handlers
		//----------------------------------

		protected function closeClickHandler(event:MouseEvent):void {
			close();
		}
		
		protected function clearClickHandler(event:MouseEvent):void {
			clearLog();
		}
		
		protected function refreshClickHandler(event:MouseEvent):void {
			refreshLog();
		}
		
		//----------------------------------
		// Getters / setters
		//----------------------------------
		
		/**
		 * The log level of the debug panel.
		 * @see mx.logging.LogEventLevel
		 */
		public function get level():int {
			return arrayTarget.level;
		}
		public function set level(value:int):void {
			arrayTarget.level = value;
		}
		
		//----------------------------------
		// Methods
		//----------------------------------
		
		protected function clearLog():void {
			arrayTarget.clear();
			refreshLog();
		}

		protected function refreshLog():void {
			invalidateLog();
		}
		
		/**
		 * Closes the panel.
		 */
		public function close():void {
			visible = false;
		}

	}
}