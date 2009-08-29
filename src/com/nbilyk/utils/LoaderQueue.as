/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import com.nbilyk.display.IPreloader;
	
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	public class LoaderQueue {
		private static const BINARY_FORMATS:String = "swf jpg gif png";
		
		private static var doInstantiate:Boolean = false;
		private static var _instance:LoaderQueue;
		
		protected var eq:EventQueue;

		public function LoaderQueue() {
			super();
			if (!doInstantiate) throw new Error("Cannot instantiate LoaderQueue directly, use getInstance()");
			
			eq = new EventQueue();
		}
		public static function get instance():LoaderQueue {
			if (!_instance) {
				doInstantiate = true;
				_instance = new LoaderQueue();
			}
			return _instance;
		}
		public function queueRequest(urlRequest:URLRequest, priority:int = 0, preloader:IPreloader = null, dataFormat:String = ""):QueuedURLLoaderEvent {
			var queuedURLLoaderEvent:QueuedURLLoaderEvent;
			
			if (!dataFormat) {
				// Default to binary mode if file url is in the BINARY_FORMATS constant.
				var fileExtension:String = StringUtils.getFileExtension(urlRequest.url);
				if (BINARY_FORMATS.indexOf(fileExtension) != -1) dataFormat = URLLoaderDataFormat.BINARY;
				else dataFormat = URLLoaderDataFormat.TEXT;
			}
			
			var previousLoaderEvent:QueuedURLLoaderEvent = getQueuedURLLoaderByURLRequest(urlRequest);
			
			if (previousLoaderEvent) {
				// URLRequest object is currently already in the queue, bind the two events.
				if (previousLoaderEvent.priority < priority) {
					// The previous loader must load before the new loader.
					previousLoaderEvent.priority = priority;
				}
				queuedURLLoaderEvent = new QueuedURLLoaderEvent(null, previousLoaderEvent, urlRequest);
			} else {
				// URLRequest object is not in the queue, create a new loader to provide to the event.
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.dataFormat = dataFormat;
				queuedURLLoaderEvent = new QueuedURLLoaderEvent(urlLoader, null, urlRequest);
			}
			queuedURLLoaderEvent.priority = priority;
			queuedURLLoaderEvent.preloader = preloader;
			eq.addEvent(queuedURLLoaderEvent);
			
			return queuedURLLoaderEvent;
		}
		public function getQueuedURLLoaderByURLRequest(urlRequest:URLRequest):QueuedURLLoaderEvent {
			var allEvents:Array = eq.events.concat(eq.currentEvent);
			
			var numEvents:int = allEvents.length;
			for (var i:int = 0; i < numEvents; i++) {
				if (allEvents[i] is QueuedURLLoaderEvent) {
					var iEvent:QueuedURLLoaderEvent = QueuedURLLoaderEvent(allEvents[i]);
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
