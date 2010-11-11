package com.nbilyk.popup {

	import flash.display.Stage;
	
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.core.IFactory;
	import mx.core.IVisualElementContainer;
	import mx.core.UIComponent;
	
	import spark.components.TitleWindow;
	import spark.layouts.BasicLayout;

	public class PopUpDescriptor {
		
		/**
		 * The parent to which this PopUp will be added.
		 */
		public var parent:UIComponent;
		
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
		 * The method that positions and sizes the container within its parent.
		 * It should have the signature:
		 * 	layoutFunction(popUpDescriptor:PopUpDescriptor):void
		 */
		public var layoutFunction:Function;
		
		/**
		 * If true, the container is modal which means that
		 * the user will not be able to interact with other popups until the window
		 * is removed.
		 * This also defines if clicking outside of the container closes the PopUp.
		 */
		public var modal:Boolean = true;
		
		/**
		 * If true, pressing escape will close the PopUp.
		 */
		public var escapeCloses:Boolean = true;
		
		/**
		 * If true, clicking outside of the PopUp area closes the PopUp.
		 */
		public var clickOutsideCloses:Boolean = true;
		
		/**
		 * If true, the container will be sized and positioned automatically on parent and view resizes. 
		 */
		public var autoLayout:Boolean = true;
		
		/**
		 * The default container is a TitleWindow. This object will set the properties on the TitleWindow if this default is used.
		 */
		public var defaultTitleWindowProperties:Object = {};

		private var _container:UIComponent;
		private var _view:UIComponent;
		private var _stage:Stage;

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

		public function get stage():Stage {
			if (!_stage) _stage = FlexGlobals.topLevelApplication.stage;
			return _stage;
		}
		
		/**
		 * The component created with the containerFactory.
		 * @see #containerFactory
		 */
		public function get container():UIComponent {
			return _container;
		}
		
		/**
		 * The component created with the viewFactory.
		 * @see #viewFactory
		 */
		public function get view():UIComponent {
			return _view;
		}
		
		/**
		 * Using the containerFactory, creates the new container.
		 */
		internal function createContainer():void {
			_container = containerFactory.newInstance();
		}
		
		/**
		 * Must only be called after createContainer();
		 */
		internal function createView():void {
			if (viewFactory) {
				_view = viewFactory.newInstance();
				if (_container is IVisualElementContainer) {
					IVisualElementContainer(_container).addElement(_view);
				} else {
					_container.addChild(_view);
				}
			}
		}
		
		/**
		 * close is called when the pop-up is closed.
		 */
		internal function close():void {
			if (closeCallback != null) closeCallback.apply(null, closeCallbackArgs);
			closeCallback = null;
			closeCallbackArgs = null;
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
	}
}