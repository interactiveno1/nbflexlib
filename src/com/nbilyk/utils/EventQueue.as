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
		
		/**
		 * Adds an event to the queue.
		 */
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
		
		/**
		 * Gets the queue's index of where an item with [priority] should go.
		 */
		protected function getPriorityIndex(priority:int):uint {
			var index:uint = length;
			if (index == 0) return 0;
			while (index > 0 && (_events[index - 1] as QueuedEvent).priority < priority) index--;
			return index;
		}
		
		/**
		 * Removes an event from the Queue.
		 */
		public function removeEvent(queuedEvent:QueuedEvent):Boolean {
			if (queuedEvent == null) {
				return removeEventByIndex(0); // Remove the next event in the queue.
			}
			var index:int = _events.indexOf(queuedEvent);
			if (index == -1) return false;
			_events.splice(index, 1);
			return true;
		}
		
		/**
		 * Removes the event at [index] from the queue.
		 */
		public function removeEventByIndex(index:int):Boolean {
			if (index > _events.length - 1) return false;
			_events.splice(index, 1);
			return true;
		}
		
		/**
		 * Removes all events from the queue.
		 */
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
		
		/**
		 * Completes the event at index 0.
		 */
		public function completeEvent():void {
			if (_currentEvent == null) {
				trace("EventQueue Warning: no event available to complete."); 
			} else {
				_currentEvent.complete();
			}
		}
		
		/**
		 * Returns true if there are no events left in the queue.
		 */
		public function get isEmpty():Boolean {
			return _events.length == 0;
		}
		
		/**
		 * The number of items in the queue.
		 */
		public function get length():uint {
			return _events.length;
		}
		
		/**
		 * The current event the queue is waiting for completion.
		 */
		public function get currentEvent():QueuedEvent {
			return _currentEvent;	
		}
		
		/**
		 * Returns an array of QueuedEvent objects.
		 */
		public function get events():Array /* Type QueuedEvent */ {
			return _events;
		}
		
		/**
		 * QueuedEvent has been completed
		 */
		private function eventCompleted(queuedEvent:QueuedEvent):void {
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
		
		//-----------------------------------
		// QueuedEvent event handlers
		//-----------------------------------
		
		/**
		 * The priority of a QueuedEvent has changed.  Change its index.
		 */
		private function priorityChangeHandler(event:Event):void {
			var targetEvent:QueuedEvent = event.currentTarget as QueuedEvent;
			var hasBeenRemoved:Boolean = removeEvent(targetEvent);
			if (hasBeenRemoved) {
				var index:uint = getPriorityIndex(targetEvent.priority);
				_events.splice(index, 0, targetEvent);
			}
		}
		
		/**
		 * QueuedEvent has been called, remove it from the _events Array
		 */
		private function calledHandler(event:Event):void {
			var queuedEvent:QueuedEvent = event.currentTarget as QueuedEvent;
			queuedEvent.removeEventListener(event.type, calledHandler);
			
			var index:int = _events.indexOf(queuedEvent);
			if (index != -1) {
				_events.splice(index, 1);
			}
		}
		
		/**
		 * The QueuedEvent has dispatched a complete event.
		 */
		private function completeHandler(event:Event):void {
			var queuedEvent:QueuedEvent = event.currentTarget as QueuedEvent;
			queuedEvent.removeEventListener(event.type, completeHandler);
			eventCompleted(queuedEvent);
		}
	}
}