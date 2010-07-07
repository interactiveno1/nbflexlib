package com.nbilyk.factory {
	import flash.events.IEventDispatcher;
	
	import mx.core.IFactory;

	/**
	 * Allows you to wrap an IFactory with a callback function.
	 */
	[DefaultProperty("factory")]
	public class CallbackFactory implements IFactory {
		
		/**
		 * The IFactory instance to call.  
		 */
		public var factory:IFactory;
		
		/**
		 * The instance the factory creates will be passed as a single argument to <code>callback</code>.
		 */
		public var callback:Function;

		public function newInstance():* {
			if (factory != null) {
				var instance:* = factory.newInstance();
				if (callback != null) {
					try {
						callback(instance);
					} catch (ignore:Error) {}
				}
				return instance;
			} else {
				return null;
			}
		}
	}
}