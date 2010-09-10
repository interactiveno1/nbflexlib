package com.nbilyk.popup {

	import flash.display.Stage;
	
	import mx.containers.TitleWindow;
	import mx.core.ApplicationGlobals;
	import mx.core.ClassFactory;
	import mx.core.Container;
	import mx.core.IFactory;
	import mx.core.UIComponent;

	public class PopUpDescriptor {
		
		/**
		 * The parent to which this PopUp will be added.
		 */
		public var parent:UIComponent;
		
		/**
		 * The desired width of the container.
		 */
		public var width:Number = 500;
		
		/**
		 * The desired height of the container.
		 */
		public var height:Number = 400;
		
		/**
		 * The minimum width of the container.
		 */
		public var minWidth:Number = 300;
		
		/**
		 * The minimum height of the container.
		 */
		public var minHeight:Number = 200;
		
		/**
		 * 
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
		 * The IFactory with which to create the View. This is expected to create an UIComponent object.
		 */
		public var viewFactory:IFactory;
		
		/**
		 * The method that positions and sizes the container within its parent.
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
		 * If true, the container will be sized and positioned automatically on parent and view resizes. 
		 */
		public var autoLayout:Boolean = true;

		private var _container:Container;
		private var _view:UIComponent;

		public function PopUpDescriptor() {
			parent = UIComponent(ApplicationGlobals.application);
			var titleWindowFactory:ClassFactory = new ClassFactory(TitleWindow);
			titleWindowFactory.properties = {showCloseButton: true};
			containerFactory = titleWindowFactory;
			layoutFunction = defaultLayoutFunction;
		}

		public function get stage():Stage {
			return ApplicationGlobals.application.stage;
		}
		
		/**
		 * The component created with the containerFactory.
		 * @see #containerFactory
		 */
		public function get container():Container {
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
			_view = viewFactory.newInstance();
			_container.addChild(view);
		}
		
		/**
		 * If a layoutFunction is not defined, the defaultLayoutFunction is used.
		 */
		protected function defaultLayoutFunction():void {
			if (!container) return;
			var parentW:Number = parent.width - paddingLeft - paddingRight;
			var parentH:Number = parent.height - paddingTop - paddingBottom;
			container.width = Math.max(minWidth, Math.min(width, parentW));
			container.height = Math.max(minHeight, Math.min(height, parentH));
			// Center the container within the parent.
			container.x = Math.round((parentW - container.width) / 2 + paddingLeft);
			container.y = Math.round((parentH - container.height) / 2 + paddingTop);
		}
	}
}