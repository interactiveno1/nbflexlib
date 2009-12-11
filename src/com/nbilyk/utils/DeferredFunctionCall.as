/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	[Event(name="called", type="flash.events.Event")]
	public class DeferredFunctionCall extends EventDispatcher {
		public static const CALLED:String = "called";
		
		public var obj:Object;
		public var func:Function;
		public var args:Array = [];
		
		private var _hasBeenCalled:Boolean = false;
		
		public function DeferredFunctionCall(_func:Function, _args:Array = null) {
			super();
			func = _func;
			if (_args) args = _args;
		}
		public function call(event:Event = null):void {
			func.apply(obj, args);
			_hasBeenCalled = true;
			dispatchEvent(new Event(CALLED));
		}
		public function get hasBeenCalled():Boolean {
			return _hasBeenCalled;
		}
	}
}