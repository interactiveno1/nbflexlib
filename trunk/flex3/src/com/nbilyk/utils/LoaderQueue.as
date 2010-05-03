/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import com.nbilyk.display.IPreloader;
	import com.nbilyk.events.QueuedUrlLoaderEvent;
	
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	public class LoaderQueue {
		private static const BINARY_FORMATS:String = "swf jpg gif png";
		
		private static var _instance:LoaderQueue;
		
		protected var eq:EventQueue;

		public function LoaderQueue(s:SingletonEnforcer) {
			super();
			eq = new EventQueue();
		}
		public static function get instance():LoaderQueue {
			if (!_instance) _instance = new LoaderQueue(new SingletonEnforcer());
			return _instance;
		}
		public function queueRequest(urlRequest:URLRequest, priority:int = 0, preloader:IPreloader = null, dataFormat:String = ""):QueuedUrlLoaderEvent {
			var queuedUrlLoaderEvent:QueuedUrlLoaderEvent;
			
			if (!dataFormat) {
				// Default to binary mode if file url is in the BINARY_FORMATS constant.
				var fileExtension:String = StringUtils.getFileExtension(urlRequest.url);
				if (BINARY_FORMATS.indexOf(fileExtension) != -1) dataFormat = URLLoaderDataFormat.BINARY;
				else dataFormat = URLLoaderDataFormat.TEXT;
			}
			
			var previousLoaderEvent:QueuedUrlLoaderEvent = getQueuedUrlLoaderByURLRequest(urlRequest);
			
			if (previousLoaderEvent) {
				// URLRequest object is currently already in the queue, bind the two events.
				if (previousLoaderEvent.priority < priority) {
					// The previous loader must load before the new loader.
					previousLoaderEvent.priority = priority;
				}
				queuedUrlLoaderEvent = new QueuedUrlLoaderEvent(null, previousLoaderEvent, urlRequest);
			} else {
				// URLRequest object is not in the queue, create a new loader to provide to the event.
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.dataFormat = dataFormat;
				queuedUrlLoaderEvent = new QueuedUrlLoaderEvent(urlLoader, null, urlRequest);
			}
			queuedUrlLoaderEvent.priority = priority;
			queuedUrlLoaderEvent.preloader = preloader;
			eq.addEvent(queuedUrlLoaderEvent);
			
			return queuedUrlLoaderEvent;
		}
		public function getQueuedUrlLoaderByURLRequest(urlRequest:URLRequest):QueuedUrlLoaderEvent {
			var allEvents:Array = eq.events.concat(eq.currentEvent);
			
			var numEvents:int = allEvents.length;
			for (var i:int = 0; i < numEvents; i++) {
				if (allEvents[i] is QueuedUrlLoaderEvent) {
					var iEvent:QueuedUrlLoaderEvent = QueuedUrlLoaderEvent(allEvents[i]);
					if (ObjectUtils.compare(urlRequest, iEvent.urlRequest)) {
						return iEvent;
					}
				}
			}
			return null;
		}
		public function removeLoaderEvent(queuedEvent:QueuedEvent):Boolean {
			return eq.removeEvent(queuedEvent);
		}
	}
}
class SingletonEnforcer {}