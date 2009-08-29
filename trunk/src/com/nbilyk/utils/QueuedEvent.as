/**
 * Copyright (c) 2007 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.events.Event;
	import flash.events.EventDispatcher;	
	
	/**
	 * @author nbilyk
	 */
	[Event(name="call", type="flash.events.Event")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="priorityChange", type="flash.events.Event")]
	public class QueuedEvent extends EventDispatcher {
		public static const CALL:String = "call";
		public static const COMPLETE:String = "complete";
		public static const PRIORITY_CHANGE:String = "priorityChange";
		
		public var obj:Object;
		public var func:Function;
		public var args:Array;
		public var dontWait:Boolean = false;
		protected var _priority:int;
		protected var _completed:Boolean = false;
		protected var _hasBeenCalled:Boolean = false;
		
		public function QueuedEvent(_func:Function = null, _args:Array = null, _priority:int = 0) {
			func = _func;
			args = _args;
			if (args == null) args = [];
			priority = _priority;
		}
		public function get completed():Boolean {
			return _completed;	
		}
		public function get hasBeenCalled():Boolean {
			return _hasBeenCalled;
		}
		public function get priority():int {
			return _priority;
		}
		public function set priority(value:int):void {
			if (value == _priority) return;
			_priority = value;
			dispatchEvent(new Event(PRIORITY_CHANGE));
		}
		public function call():void {
			dispatchEvent(new Event(CALL));
			if (func != null) func.apply(obj, args);
			_hasBeenCalled = true;
		}
		public function complete():void {
			_completed = true;
			dispatchEvent(new Event(COMPLETE));
		}
		
	}
}