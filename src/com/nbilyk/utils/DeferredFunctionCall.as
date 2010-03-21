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
		public var args:Array;
		public var appendEvent:Boolean;
		
		private var _hasBeenCalled:Boolean = false;
		
		public function DeferredFunctionCall(funcVal:Function, argsVal:Array = null, appendEventVal:Boolean = false) {
			super();
			func = funcVal;
			args = (argsVal == null) ? [] : argsVal;
			appendEvent = appendEventVal;
		}
		public function call(event:Event = null):void {
			if (appendEvent) func.apply(obj, args.concat(event));
			else func.apply(obj, args);
			_hasBeenCalled = true;
			dispatchEvent(new Event(CALLED));
		}
		public function get hasBeenCalled():Boolean {
			return _hasBeenCalled;
		}
		
		public static function createHandler(func:Function, args:Array = null, appendEvent:Boolean = false):Function {
			var dfc:DeferredFunctionCall = new DeferredFunctionCall(func, args, appendEvent);
			return dfc.call;
		}
	}
}