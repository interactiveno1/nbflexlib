package com.nbilyk.utils {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	/**
	 * The loader queue manager allows you to tie 
	 */
	public class LoaderQueueManager {
		
		private static var _instance:LoaderQueueManager;
		
		private var dict:Dictionary = new Dictionary(true); // Type DisplayObject => LoaderQueue
		
		public function LoaderQueueManager(s:SingletonEnforcer) {
		}
		
		public static function get instance():LoaderQueueManager {
			if (!_instance) _instance = new LoaderQueueManager(new SingletonEnforcer());
			return _instance;
		}
		
		public function getLoaderQueue(displayObject:DisplayObject):LoaderQueue {
			var existingQueue:LoaderQueue = dict[displayObject] as LoaderQueue;
			if (existingQueue) return existingQueue;
			var newQueue:LoaderQueue = new LoaderQueue();
			dict[displayObject] = newQueue;
			
			newQueue.isPaused = !displayObject.stage;
			displayObject.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
			displayObject.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler, false, 0, true);
			return newQueue;
		}
		
		private function addedToStageHandler(event:Event):void {
			var displayObject:DisplayObject = DisplayObject(event.currentTarget);
			var existingQueue:LoaderQueue = dict[displayObject] as LoaderQueue;
			if (!existingQueue) return;
			existingQueue.isPaused = false;
		}
		
		private function removedFromStageHandler(event:Event):void {
			var displayObject:DisplayObject = DisplayObject(event.currentTarget);
			var existingQueue:LoaderQueue = dict[displayObject] as LoaderQueue;
			if (!existingQueue) return;
			existingQueue.isPaused = true;
		}

	}
}
class SingletonEnforcer {}