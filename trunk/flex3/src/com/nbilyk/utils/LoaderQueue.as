/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import com.nbilyk.display.IPreloader;
	import com.nbilyk.events.QueuedUrlLoaderEvent;
	
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class LoaderQueue {
		private static const BINARY_FORMATS:String = "swf jpg gif png";
		
		protected var eQ:EventQueue;

		public function LoaderQueue() {
			super();
			eQ = new EventQueue();
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
			eQ.addEvent(queuedUrlLoaderEvent);
			
			return queuedUrlLoaderEvent;
		}
		
		public function getQueuedUrlLoaderByURLRequest(urlRequest:URLRequest):QueuedUrlLoaderEvent {
			var allEvents:Array = eQ.events.concat(eQ.currentEvent);
			
			for each (var iEvent:QueuedEvent in allEvents) {
				if (iEvent is QueuedUrlLoaderEvent) {
					if (ObjectUtils.compare(urlRequest, QueuedUrlLoaderEvent(iEvent).urlRequest)) {
						return QueuedUrlLoaderEvent(iEvent);
					}
				}
			}
			return null;
		}
		
		public function removeLoaderEvent(queuedEvent:QueuedUrlLoaderEvent):Boolean {
			return eQ.removeEvent(queuedEvent);
		}
		
		//--------------------------------
		// Event queue wrapper methods.
		//--------------------------------
		
		/**
		 * If isPaused is true, the next event will not be called on completion.
		 */
		public function get isPaused():Boolean {
			return eQ.isPaused;
		}
		
		public function set isPaused(value:Boolean):void {
			eQ.isPaused = value;
		}
		
		/**
		 * Sets isPaused to true.
		 */
		public function pause():void {
			eQ.isPaused = true;
		}
		
		/**
		 * Sets isPaused to false.
		 */
		public function resume():void {
			eQ.isPaused = false;
		}
	}
}
