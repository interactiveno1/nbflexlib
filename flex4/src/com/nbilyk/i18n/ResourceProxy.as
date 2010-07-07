package com.nbilyk.i18n {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.setTimeout;
	
	import mx.core.IPropertyChangeNotifier;
	import mx.events.PropertyChangeEvent;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.utils.UIDUtil;

	[Bindable("change")]
	public dynamic class ResourceProxy extends Proxy implements IPropertyChangeNotifier {

		private var _id:String;
		private var _bundleName:String;
		
		protected var dispatcher:EventDispatcher;
		protected var resourceManager:IResourceManager;
		
		public function ResourceProxy() {
			super();
			dispatcher = new EventDispatcher(this);
			resourceManager = ResourceManager.getInstance();
			resourceManager.addEventListener(Event.CHANGE, resourceManagerChangeHandler, false, 0, true);
		}
		
		/**
		 * The name of the resource bundle this proxy object uses.
		 */
		public function get bundleName():String {
			return _bundleName;
		}
		
		public function set bundleName(value:String):void {
			_bundleName = value;
		}
		

		/**
		 *  Called when the resource manager dispatches a change event.
		 */
		public function resourceManagerChangeHandler(event:Event):void {
			dispatcher.dispatchEvent(event);
		}

		override flash_proxy function callProperty(name:*, ... args):* {
			return resourceManager.getString(bundleName, String(name), args);
		}

		override flash_proxy function getProperty(name:*):* {
			return resourceManager.getString(bundleName, String(name));
		}

		override flash_proxy function setProperty(name:*, value:*):void {
			
		}

		//----------------------------------------
		// IPropertyChangeNotifier methods
		//----------------------------------------

		public function get uid():String {
			if (_id === null)
				_id = UIDUtil.createUID();

			return _id;
		}

		public function set uid(value:String):void {
			_id = value;
		}

		/**
		 *  @see flash.events.EventDispatcher#addEventListener()
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		/**
		 *  @see flash.events.EventDispatcher#removeEventListener()
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			dispatcher.removeEventListener(type, listener, useCapture);
		}

		/**
		 *  @see flash.events.EventDispatcher#dispatchEvent()
		 */
		public function dispatchEvent(event:Event):Boolean {
			return dispatcher.dispatchEvent(event);
		}

		/**
		 *  @see flash.events.EventDispatcher#hasEventListener()
		 */
		public function hasEventListener(type:String):Boolean {
			return dispatcher.hasEventListener(type);
		}

		/**
		 *  @see flash.events.EventDispatcher#willTrigger()
		 */
		public function willTrigger(type:String):Boolean {
			return dispatcher.willTrigger(type);
		}
	}
}