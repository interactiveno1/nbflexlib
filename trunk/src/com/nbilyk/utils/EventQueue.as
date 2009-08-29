/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(name="nextEvent", type="com.nbilyk.utils.EventQueue")]
	[Event(name="complete", type="com.nbilyk.utils.EventQueue")]
	public class EventQueue extends EventDispatcher {
		public static const NEXT_EVENT:String = "nextEvent";
		public static const COMPLETE:String = "complete";
		
		private var _currentEvent:QueuedEvent;
		private var _events:Array;
		private var dispatcher:EventDispatcher;

		public function EventQueue() {
			dispatcher = new EventDispatcher(this);
			_events = new Array();
		}
		public function addEvent(queuedEvent:QueuedEvent):void {
			var index:uint = getPriorityIndex(queuedEvent.priority);
			_events.splice(index, 0, queuedEvent);
			
			if (!queuedEvent.completed) {
				queuedEvent.addEventListener(QueuedEvent.PRIORITY_CHANGE, priorityChangeHandler);
				queuedEvent.addEventListener(QueuedEvent.CALL, calledHandler);
				queuedEvent.addEventListener(QueuedEvent.COMPLETE, completeHandler);
			}
			if (_currentEvent == null) doNextEvent();
		}
		protected function getPriorityIndex(priority:int):uint {
			var index:uint = length;
			if (index == 0) return 0;
			while (index > 0 && (_events[index - 1] as QueuedEvent).priority < priority) index--;
			return index;
		}
		public function removeEvent(queuedEvent:QueuedEvent):Boolean {
			if (queuedEvent == null) {
				return removeEventByIndex(0); // Remove the next event in the queue.
			}
			var index:int = _events.indexOf(queuedEvent);
			if (index == -1) return false;
			_events.splice(index, 1);
			return true;
		}
		public function removeEventByIndex(index:int):Boolean {
			if (index > _events.length - 1) return false;
			_events.splice(index, 1);
			return true;
		}
		public function removeAllEvents():void {
			_events = new Array();
		}
		protected function doNextEvent():void {
			if (length == 0) return;
			
			var evt:Event = new Event(NEXT_EVENT);
			dispatchEvent(evt);
			
			var queuedEvent:QueuedEvent = (_events[0] as QueuedEvent);
			if (!queuedEvent.hasBeenCalled && !queuedEvent.completed) {
				_currentEvent = queuedEvent;
				queuedEvent.call();
				
				if (queuedEvent.dontWait) {
					// Force finish because we don't want to wait for an eventCompleted call.
					queuedEvent.complete();
				}
			} else {
				_events.shift();
			}
		}
		public function completeEvent():void {
			if (_currentEvent == null) {
				trace("EventQueue Warning: no event available to complete."); 
			} else {
				_currentEvent.complete();
			}
		}
		public function get isEmpty():Boolean {
			return _events.length == 0;
		}
		public function get length():uint {
			return _events.length;
		}
		public function get currentEvent():QueuedEvent {
			return _currentEvent;	
		}
		public function get events():Array {
			return _events;
		}
		private function eventCompleted(queuedEvent:QueuedEvent):void {
			// QueuedEvent has been completed
			if (queuedEvent == _currentEvent) {
				_currentEvent = null;
				if (_events.length == 0) {
					var evt:Event = new Event(COMPLETE);
					dispatchEvent(evt);
				} else {
					doNextEvent();
				}
			}
		}
		// QueuedEvent event handlers
		private function priorityChangeHandler(event:Event):void {
			var targetEvent:QueuedEvent = event.currentTarget as QueuedEvent;
			var hasBeenRemoved:Boolean = removeEvent(targetEvent);
			if (hasBeenRemoved) {
				var index:uint = getPriorityIndex(targetEvent.priority);
				_events.splice(index, 0, targetEvent);
			}
		}
		private function calledHandler(event:Event):void {
			// QueuedEvent has been called, remove it from the _events Array
			var queuedEvent:QueuedEvent = event.currentTarget as QueuedEvent;
			queuedEvent.removeEventListener(event.type, calledHandler);
			
			var index:int = _events.indexOf(queuedEvent);
			if (index != -1) {
				_events.splice(index, 1);
			}
		}
		private function completeHandler(event:Event):void {
			var queuedEvent:QueuedEvent = event.currentTarget as QueuedEvent;
			queuedEvent.removeEventListener(event.type, completeHandler);
			eventCompleted(queuedEvent);
		}
	}
}