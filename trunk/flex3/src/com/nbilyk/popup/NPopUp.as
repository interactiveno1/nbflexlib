package com.nbilyk.popup {
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.containers.TitleWindow;
	import mx.core.ApplicationGlobals;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;

	public class NPopUp {
		
		[ArrayElementType("com.nbilyk.popup.NPopUp")]
		private static var popUps:Array = [];
		
		private var _popUpDescriptor:PopUpDescriptor;
		
		/**
		 * Returns the top-most NPopUp.
		 */
		public static function getCurrentPopUp():NPopUp {
			var n:uint = popUps.length;
			if (!n) return null;
			return popUps[n - 1];
		}
		
		/**
		 * Creates a new pop-up using the given PopUpDescriptor.
		 */
		public static function createPopUp(popUpDescriptor:PopUpDescriptor):void {
			if (!popUpDescriptor.stage || !popUpDescriptor.parent) return;
			popUps.push(new NPopUp(popUpDescriptor));
		}
		
		
		/**
		 * Closes the pop-up with the given popUpDescriptor.
		 * If no popUpDescriptor is provided, the top-most popUp will be closed.
		 * 
		 * @return Returns true if an open NPopUp with the given descriptor has been found
		 * and has been successfully closed.
		 */
		public static function closePopUp(popUpDescriptor:PopUpDescriptor = null):Boolean {
			if (popUpDescriptor) {
				var index:int = getPopUpIndex(popUpDescriptor);
				if (index == -1) return false;
				return NPopUp(popUps[index]).close();
			} else {
				var n:uint = popUps.length;
				if (!n) return false;
				return NPopUp(popUps[n - 1]).close();
			}
		}
		
		/**
		 * Constructs a new PopUp, using the container, view, and other settings from PopUpDescriptor.
		 * The NPopUp will then be added to the Flex PopUpManager, and listeners will be added to respond to resize, close, and keyboard events.
		 */
		public function NPopUp(popUpDescriptorVal:PopUpDescriptor) {
			if (!popUpDescriptorVal.stage || !popUpDescriptorVal.parent) return;
			_popUpDescriptor = popUpDescriptorVal;
			
			_popUpDescriptor.createContainer();
			_popUpDescriptor.createView();
			
			PopUpManager.addPopUp(_popUpDescriptor.container, _popUpDescriptor.parent, _popUpDescriptor.modal);
			callLater(layout);
			
			_popUpDescriptor.container.addEventListener(CloseEvent.CLOSE, closeHandler);
			if (_popUpDescriptor.view) _popUpDescriptor.view.addEventListener(CloseEvent.CLOSE, closeHandler);
			if (_popUpDescriptor.autoLayout) {
				_popUpDescriptor.parent.addEventListener(ResizeEvent.RESIZE, resizeHandler);
			}
			if (_popUpDescriptor.modal && _popUpDescriptor.clickOutsideCloses) {
				_popUpDescriptor.stage.addEventListener(MouseEvent.CLICK, stageClickHandler);
			}
			if (_popUpDescriptor.escapeCloses) {
				_popUpDescriptor.stage.addEventListener(KeyboardEvent.KEY_DOWN, stageKeyDownHandler);	
			}
		}
		
		public function get popUpDescriptor():PopUpDescriptor {
			return _popUpDescriptor;
		}
		
		private function closeHandler(event:Event):void {
			close();
		}
		
		private function resizeHandler(event:ResizeEvent):void {
			callLater(layout);
		}
		
		private function callLater(method:Function, args:Array = null):void {
			ApplicationGlobals.application.callLater(method, args);
		}
		
		private function layout():void {
			popUpDescriptor.layoutFunction();
		}
		
		private function stageClickHandler(event:MouseEvent):void {
			if (!event.stageX || !event.stageY || !popUpDescriptor.container.initialized) return;
			if (!popUpDescriptor.container.hitTestPoint(event.stageX, event.stageY)) {
				// Close only when clicking outside of the image uploader.
				close();
			}
		}
		
		private function stageKeyDownHandler(event:KeyboardEvent):void {
			if (event.keyCode == Keyboard.ESCAPE) {
				closePopUp();
				event.stopImmediatePropagation();
			}
		}
		
		/**
		 * Closes the popUp.  
		 * @return Returns true if the PopUp was open and has been closed.
		 */
		public function close():Boolean {
			var index:int = popUps.indexOf(this);
			if (index == -1) return false; // Not currently open.
			popUps.splice(index, 1);
			
			popUpDescriptor.container.removeEventListener(CloseEvent.CLOSE, closeHandler);
			if (popUpDescriptor.view) {
				popUpDescriptor.view.removeEventListener(CloseEvent.CLOSE, closeHandler);
			}
			popUpDescriptor.parent.removeEventListener(ResizeEvent.RESIZE, resizeHandler);
			popUpDescriptor.stage.removeEventListener(MouseEvent.CLICK, stageClickHandler);
			popUpDescriptor.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stageKeyDownHandler);
			PopUpManager.removePopUp(popUpDescriptor.container);
			popUpDescriptor.close();
			return true;
		}
		
		/**
		 * @return Returns the index of the NPopUp with the given popUpDesscriptor.
		 * Returns -1 if none have been found.
		 */
		private static function getPopUpIndex(popUpDescriptor:PopUpDescriptor):int {
			var i:int = 0;
			for each (var popUp:NPopUp in popUps) {
				if (popUp.popUpDescriptor == popUpDescriptor) return i;
				i++;
			}
			return -1;
		}
	}
}