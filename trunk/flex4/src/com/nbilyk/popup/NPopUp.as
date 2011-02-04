package com.nbilyk.popup {
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.containers.TitleWindow;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;

	public class NPopUp {
		
		private static var popUps:Vector.<NPopUp> = new Vector.<NPopUp>();
		
		private var _popUpDescriptor:IPopUpDescriptor;
		
		private var popUpComponent:UIComponent;
		
		/**
		 * Returns the top-most NPopUp.
		 */
		public static function getCurrentPopUp():NPopUp {
			var n:uint = popUps.length;
			if (!n) return null;
			return popUps[n - 1];
		}
		
		/**
		 * Returns a copy of the Vector of current NPopUp objects.
		 */
		public static function getAllPopUps():Vector.<NPopUp> {
			return popUps.slice();
		}
		
		/**
		 * Creates a new pop-up using the given PopUpDescriptor.
		 */
		public static function createPopUp(popUpDescriptor:IPopUpDescriptor):void {
			if (!stage || !popUpDescriptor.parent) return;
			if (!popUps.length) {
				// First pop-up, add the stage click and keyboard listeners.
				stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, stageKeyDownHandler);
			}
			popUps.push(new NPopUp(popUpDescriptor));
		}
		
		/**
		 * Closes the pop-up with the given popUpDescriptor.
		 * If no popUpDescriptor is provided, the top-most popUp will be closed.
		 * 
		 * @return Returns true if an open NPopUp with the given descriptor has been found
		 * and has been successfully closed.
		 */
		public static function closePopUp(popUpDescriptor:IPopUpDescriptor = null):Boolean {
			if (popUpDescriptor) {
				var index:int = getPopUpIndex(popUpDescriptor);
				if (index == -1) return false;
				return popUps[index].close();
			} else {
				var n:uint = popUps.length;
				if (!n) return false;
				return popUps[n - 1].close();
			}
		}
		
		/**
		 * Closes all currently open pop-ups.
		 */
		public static function closeAllPopUps():void {
			var popUpsClone:Vector.<NPopUp> = popUps.slice();
			for each (var popUp:NPopUp in popUpsClone) {
				popUp.close();
			}
		}

		
		private static function removePopUp(nPopUp:NPopUp):Boolean {
			var index:int = popUps.indexOf(nPopUp);
			if (index == -1) return false; // Not currently open.
			popUps.splice(index, 1);
			
			if (!popUps.length) {
				// Last pop-up removed, remove the stage click and keyboard listeners.
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, stageKeyDownHandler);
			}
			return true;
		}
		
		/**
		 * Just a convenience method to get the Stage.
		 */
		private static function get stage():Stage {
			return FlexGlobals.topLevelApplication.stage;
		}
		
		/**
		 * The mouse down / mouse up insanity instead of a click is to account for things like TitleWindow dispatching 
		 * the close event on mouse down, which can mess up multiple pop ups because the close event will close the 
		 * pop-up before the click event, causing the click event to possibly close the next pop-up as well.
		 */
		private static function mouseDownHandler(event:MouseEvent):void {
			var currentPopUp:NPopUp = getCurrentPopUp();
			if (!currentPopUp.popUpDescriptor.clickOutsideCloses || !currentPopUp.popUpDescriptor.modal) return;
			if (!event.stageX || !event.stageY || !currentPopUp.popUpComponent.initialized) return;
			if (!currentPopUp.popUpComponent.hitTestPoint(event.stageX, event.stageY)) {
				stage.addEventListener(MouseEvent.MOUSE_UP, stageMouseUpHandler);
			}
		}
		
		private static function stageMouseUpHandler(event:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_UP, stageMouseUpHandler);
			var currentPopUp:NPopUp = getCurrentPopUp();
			if (!event.stageX || !event.stageY || !currentPopUp.popUpComponent.initialized) return;
			if (!currentPopUp.popUpComponent.hitTestPoint(event.stageX, event.stageY)) {
				// Close only when clicking outside of the image uploader.
				currentPopUp.close();
			}
		}
		
		private static function stageKeyDownHandler(event:KeyboardEvent):void {
			var currentPopUp:NPopUp = getCurrentPopUp();
			if (!currentPopUp.popUpDescriptor.escapeCloses) return;
			if (event.keyCode == Keyboard.ESCAPE) {
				currentPopUp.close();
				event.stopImmediatePropagation();
			}
		}
		
		/**
		 * Constructs a new PopUp, using the container, view, and other settings from IPopUpDescriptor.
		 * The NPopUp will then be added to the Flex PopUpManager, and listeners will be added to respond to resize, close, and keyboard events.
		 */
		public function NPopUp(popUpDescriptorVal:IPopUpDescriptor) {
			if (!stage || !popUpDescriptorVal.parent) return;
			_popUpDescriptor = popUpDescriptorVal;
			
			popUpComponent = _popUpDescriptor.createPopUp();
			
			PopUpManager.addPopUp(popUpComponent, _popUpDescriptor.parent, _popUpDescriptor.modal);
			callLater(layout);
			
			popUpComponent.addEventListener(CloseEvent.CLOSE, closeHandler);
			if (_popUpDescriptor.autoLayout) {
				_popUpDescriptor.parent.addEventListener(ResizeEvent.RESIZE, resizeHandler);
			}
		}
		
		public function get popUpDescriptor():IPopUpDescriptor {
			return _popUpDescriptor;
		}
		
		private function closeHandler(event:Event):void {
			close();
		}
		
		private function resizeHandler(event:ResizeEvent):void {
			callLater(layout);
		}
		
		private function callLater(method:Function, args:Array = null):void {
			FlexGlobals.topLevelApplication.callLater(method, args);
		}
		
		private function layout():void {
			popUpDescriptor.layoutFunction.apply(null, [popUpDescriptor].concat(popUpDescriptor.layoutFunctionArgs));
		}
		
		
		/**
		 * Closes the popUp.  
		 * @return Returns true if the PopUp was open and has been closed.
		 */
		public function close():Boolean {
			var success:Boolean = removePopUp(this);
			if (!success) return false;
			popUpComponent.removeEventListener(CloseEvent.CLOSE, closeHandler);
			popUpDescriptor.parent.removeEventListener(ResizeEvent.RESIZE, resizeHandler);
			PopUpManager.removePopUp(popUpComponent);
			popUpDescriptor.close();
			return true;
		}
		
		/**
		 * @return Returns the index of the NPopUp with the given popUpDesscriptor.
		 * Returns -1 if none have been found.
		 */
		private static function getPopUpIndex(popUpDescriptor:IPopUpDescriptor):int {
			var i:int = 0;
			for each (var popUp:NPopUp in popUps) {
				if (popUp.popUpDescriptor == popUpDescriptor) return i;
				i++;
			}
			return -1;
		}
	}
}