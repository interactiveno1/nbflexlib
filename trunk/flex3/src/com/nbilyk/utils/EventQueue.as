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
		private var _events:Array; /* Type QueuedEvent */
		private var _isPaused:Boolean;

		public function EventQueue() {
			setEvents(new Array());
		}
		
		/**
		 * Adds an event to the queue.
		 */
		public function addEvent(queuedEvent:QueuedEvent):void {
			var index:uint = getPriorityIndex(queuedEvent.priority);
			events.splice(index, 0, queuedEvent);
			
			if (!queuedEvent.completed) {
				queuedEvent.addEventListener(QueuedEvent.PRIORITY_CHANGE, priorityChangeHandler, false, 0, true);
				queuedEvent.addEventListener(QueuedEvent.CALL, calledHandler, false, 0, true);
				queuedEvent.addEventListener(QueuedEvent.COMPLETE, completeHandler, false, 0, true);
			}
			if (currentEvent == null) doNextEvent();
		}
		
		/**
		 * Gets the queue's index of where an item with [priority] should go.
		 */
		protected function getPriorityIndex(priority:int):uint {
			var index:uint = length;
			if (index == 0) return 0;
			while (index > 0 && (events[index - 1] as QueuedEvent).priority < priority) index--;
			return index;
		}
		
		/**
		 * Removes an event from the Queue.
		 */
		public function removeEvent(queuedEvent:QueuedEvent):Boolean {
			if (queuedEvent == null) {
				return removeEventByIndex(0); // Remove the next event in the queue.
			}
			var index:int = events.indexOf(queuedEvent);
			if (index == -1) return false;
			events.splice(index, 1);
			return true;
		}
		
		/**
		 * Removes the event at [index] from the queue.
		 */
		public function removeEventByIndex(index:int):Boolean {
			if (index > events.length - 1) return false;
			events.splice(index, 1);
			return true;
		}
		
		/**
		 * Removes all events from the queue.
		 */
		public function removeAllEvents():void {
			setEvents(new Array());
			setCurrentEvent(null);
		}
		
		protected function doNextEvent():void {
			if (length == 0 || currentEvent || isPaused) return;
			
			var evt:Event = new Event(NEXT_EVENT);
			dispatchEvent(evt);
			
			var queuedEvent:QueuedEvent = (events[0] as QueuedEvent);
			if (!queuedEvent.hasBeenCalled && !queuedEvent.completed) {
				setCurrentEvent(queuedEvent);
				queuedEvent.call();
				
				if (queuedEvent.dontWait) {
					// Force finish because we don't want to wait for an eventCompleted call.
					queuedEvent.complete();
				}
			} else {
				events.shift();
			}
		}
		
		/**
		 * Completes the event at index 0.
		 */
		public function completeEvent():void {
			if (currentEvent == null) {
				trace("EventQueue Warning: no event available to complete."); 
			} else {
				currentEvent.complete();
			}
		}
		
		//---------------------------
		// Getters / setters
		//---------------------------
		
		/**
		 * Returns true if there are no events left in the queue.
		 */
		public function get isEmpty():Boolean {
			return events.length == 0;
		}
		
		/**
		 * The number of items in the queue.
		 */
		public function get length():uint {
			return events.length;
		}
		
		/**
		 * The current event the queue is waiting for completion.
		 */
		public function get currentEvent():QueuedEvent {
			return _currentEvent;	
		}
		
		protected function setCurrentEvent(value:QueuedEvent):void {
			_currentEvent = value;
		}
		
		/**
		 * Returns an array of QueuedEvent objects.
		 */
		[ArrayElementType("com.nbilyk.utils.QueuedEvent")]
		public function get events():Array {
			return _events;
		}
		
		protected function setEvents(value:Array):void {
			_events = value;
		}
		
		/**
		 * If isPaused is true, the next event will not be called on completion.
		 */
		public function get isPaused():Boolean {
			return _isPaused;
		}
		
		public function set isPaused(value:Boolean):void {
			if (_isPaused == value) return; // no-op
			_isPaused = value;
			if (!value) {
				doNextEvent();
			}
		}
		
		/**
		 * Sets isPaused to true.
		 */
		public function pause():void {
			isPaused = true;
		}
		
		/**
		 * Sets isPaused to false.
		 */
		public function resume():void {
			isPaused = false;
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
				events.splice(index, 0, targetEvent);
			}
		}
		
		/**
		 * QueuedEvent has been called, remove it from the events Array
		 */
		private function calledHandler(event:Event):void {
			var queuedEvent:QueuedEvent = event.currentTarget as QueuedEvent;
			queuedEvent.removeEventListener(event.type, calledHandler);
			
			var index:int = events.indexOf(queuedEvent);
			if (index != -1) {
				events.splice(index, 1);
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
		
		/**
		 * QueuedEvent has been completed
		 */
		private function eventCompleted(queuedEvent:QueuedEvent):void {
			if (queuedEvent == currentEvent) {
				setCurrentEvent(null);
				if (events.length == 0) {
					var evt:Event = new Event(COMPLETE);
					dispatchEvent(evt);
				} else {
					doNextEvent();
				}
			}
		}
	}
}