package com.nbilyk.popup {

	import flash.display.Stage;
	
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.core.IFactory;
	import mx.core.IVisualElementContainer;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	
	import spark.components.TitleWindow;
	import spark.layouts.BasicLayout;

	public class PopUpDescriptor implements IPopUpDescriptor {
		
		/**
		 * The desired width of the container.
		 */
		public var width:Number;
		
		/**
		 * The desired height of the container.
		 */
		public var height:Number;
		
		/**
		 * The minimum width of the container.
		 */
		public var minWidth:Number = 50;
		
		/**
		 * The minimum height of the container.
		 */
		public var minHeight:Number = 50;
		
		/**
		 * Padding is the minimum distance between the pop-up container and parent. 
		 */
		public var paddingLeft:Number = 10;
		
		/**
		 * @copy #paddingLeft
		 */
		public var paddingTop:Number = 10;
		
		/**
		 * @copy #paddingLeft
		 */
		public var paddingRight:Number = 10;
		
		/**
		 * @copy #paddingLeft
		 */
		public var paddingBottom:Number = 10;
		
		/**
		 * When the popUp is closed, this closeCallback function will be called, passing closeCallbackArgs.
		 */
		public var closeCallback:Function;
		
		/**
		 * @copy #closeCallback
		 */
		public var closeCallbackArgs:Array;
		
		/**
		 * The IFactory with which to create the Container.  This is expected to create a Container object. 
		 */
		public var containerFactory:IFactory;
		
		/**
		 * The IFactory with which to create the component to be placed in the Container. This is expected to create an UIComponent object.
		 */
		public var viewFactory:IFactory;
		
		/**
		 * The default container is a TitleWindow. This object will set the properties on the TitleWindow if this default is used.
		 */
		public var defaultTitleWindowProperties:Object = {};
		
		private var _container:UIComponent;
		private var _view:UIComponent;
		private var _parent:UIComponent;
		private var _modal:Boolean = true;
		private var _escapeCloses:Boolean = true;
		private var _clickOutsideCloses:Boolean = true;
		private var _autoLayout:Boolean = true;
		private var _layoutFunction:Function;
		private var _layoutFunctionArgs:Array = [];

		public function PopUpDescriptor() {
			parent = UIComponent(FlexGlobals.topLevelApplication);
			var titleWindowFactory:ClassFactory = new ClassFactory(TitleWindow);
			titleWindowFactory.properties = defaultTitleWindowProperties;
			var basicLayout:BasicLayout = new BasicLayout();
			basicLayout.clipAndEnableScrolling = true;
			titleWindowFactory.properties.layout = basicLayout;
			containerFactory = titleWindowFactory;
			layoutFunction = defaultLayoutFunction;
		}

		/**
		 * The container created by the containerFactory. 
		 * If this is set manually, the containerFactory will not be used.
		 */
		public function get container():UIComponent {
			return _container;
		}
		
		public function set container(value:UIComponent):void {
			_container = value;
		}
		
		/**
		 * The view created by the viewFactory.  
		 * If this is set manually, the viewFactory will not be used.
		 */
		public function get view():UIComponent {
			return _view;
		}
		
		public function set view(value:UIComponent):void {
			_view = value;
		}

		/**
		 * @inheritDoc
		 */
		public function get parent():UIComponent {
			return _parent;
		}

		public function set parent(value:UIComponent):void {
			_parent = value;
		}
		
		
		/**
		 * Using the containerFactory, creates the new container.
		 */
		public function createPopUp():UIComponent {
			if (!_container) _container = containerFactory.newInstance();
			
			if (viewFactory) _view = viewFactory.newInstance();
			if (view) {
				view.addEventListener(CloseEvent.CLOSE, viewCloseHandler, false, 0, true);
				if (!view.parent) {
					if (_container is IVisualElementContainer) {
						IVisualElementContainer(_container).addElement(view);
					} else {
						_container.addChild(view);
					}
				}
			}
			
			return _container;
		}
		
		/**
		 * Bubble the view's close event to the container.
		 */
		private function viewCloseHandler(event:CloseEvent):void {
			if (container && !event.bubbles) container.dispatchEvent(event);
		}
		
		/**
		 * @inheritDoc
		 */
		public function close():void {
			if (closeCallback != null) closeCallback.apply(null, closeCallbackArgs);
			closeCallback = null;
			closeCallbackArgs = null;
			_container = null;
			_view = null;
		}
		
		/**
		 * If a layoutFunction is not defined, the defaultLayoutFunction is used.
		 */
		protected function defaultLayoutFunction(popUpDescriptor:PopUpDescriptor):void {
			if (!container) return;
			var parentW:Number = parent.width - paddingLeft - paddingRight;
			var parentH:Number = parent.height - paddingTop - paddingBottom;
			var w:Number = isNaN(width) ? container.measuredWidth : width;
			var h:Number = isNaN(height) ? container.measuredHeight : height;
			var newW:Number = Math.max(minWidth, Math.min(w, parentW));
			var newH:Number = Math.max(minHeight, Math.min(h, parentH));
			//container.setActualSize(newW, newH);
			container.width = newW;
			container.height = newH;
			// Center the container within the parent.
			container.move(Math.round((parentW - newW) / 2 + paddingLeft), Math.round((parentH - newH) / 2 + paddingTop));
		}

		/**
		 * @inheritDoc
		 */
		public function get modal():Boolean {
			return _modal;
		}

		public function set modal(value:Boolean):void {
			_modal = value;
		}

		/**
		 * @inheritDoc
		 */
		public function get escapeCloses():Boolean {
			return _escapeCloses;
		}

		public function set escapeCloses(value:Boolean):void {
			_escapeCloses = value;
		}

		/**
		 * @inheritDoc
		 */
		public function get clickOutsideCloses():Boolean {
			return _clickOutsideCloses;
		}

		public function set clickOutsideCloses(value:Boolean):void {
			_clickOutsideCloses = value;
		}

		/**
		 * @inheritDoc
		 */
		public function get autoLayout():Boolean {
			return _autoLayout;
		}

		public function set autoLayout(value:Boolean):void {
			_autoLayout = value;
		}

		/**
		 * @inheritDoc
		 */
		public function get layoutFunction():Function {
			return _layoutFunction;
		}

		public function set layoutFunction(value:Function):void {
			_layoutFunction = value;
		}

		/**
		 * @inheritDocs
		 */
		public function get layoutFunctionArgs():Array {
			return _layoutFunctionArgs;
		}

		/**
		 * @private
		 */
		public function set layoutFunctionArgs(value:Array):void {
			_layoutFunctionArgs = value;
		}


	}
}