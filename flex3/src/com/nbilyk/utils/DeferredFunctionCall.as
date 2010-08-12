/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	[Event(name="called", type="flash.events.Event")]
	public class DeferredFunctionCall extends EventDispatcher {
		public static const CALLED:String = "called";

		public var obj:Object;
		public var func:Function;
		public var args:Array;
		public var appendEvent:Boolean;

		private var _hasBeenCalled:Boolean = false;

		/**
		 * @param funcVal The function to call.  
		 * @param argsVal The arguments to pass to funcVal.
		 * @param appendEvent If true, the event passed to call will be appended to the arguments.
		 */
		public function DeferredFunctionCall(funcVal:Function, argsVal:Array = null, appendEventVal:Boolean = false) {
			super();
			func = funcVal;
			args = (argsVal == null) ? [] : argsVal;
			appendEvent = appendEventVal;
		}
		
		/**
		 * Calls <code>func</code> with <code>args</code> as the arguments.
		 * If appendEvent is true, the event passed to call will be added to the end of the arguments list.
		 */
		public function call(event:Event = null):void {
			if (event) IEventDispatcher(event.currentTarget).removeEventListener(event.type, call);
			if (appendEvent) func.apply(obj, args.concat(event));
			else func.apply(obj, args);
			_hasBeenCalled = true;
			dispatchEvent(new Event(CALLED));
		}

		/**
		 * True if this deffered function has been called at least once.
		 */
		public function get hasBeenCalled():Boolean {
			return _hasBeenCalled;
		}

		/**
		 * A utility method to create a deffered function call and give its call method as an event listener function.
		 */
		public static function createHandler(func:Function, args:Array = null, appendEvent:Boolean = false):Function {
			var dfc:DeferredFunctionCall = new DeferredFunctionCall(func, args, appendEvent);
			return dfc.call;
		}
	}
}