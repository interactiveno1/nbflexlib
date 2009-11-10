/**
 * Copyright (c) 2007 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import com.nbilyk.display.IPreloader;
	import com.nbilyk.events.LoaderCreationEvent;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;	

	[Event(name="loaderCreationComplete", type="com.nbilyk.events.LoaderCreationEvent")]
	[Event(name="loaderCreationError", type="com.nbilyk.events.LoaderCreationEvent")]
	public class QueuedURLLoaderEvent extends QueuedEvent {
		private var _urlLoader:URLLoader;
		private var _urlRequest:URLRequest;
		private var _buildLoader:Boolean = false;
		public var preloader:IPreloader;
		private var showingPreloader:Boolean = false;
		private var _boundEvent:QueuedURLLoaderEvent;
		
		// If the download is past this percent after update interval, don't show the preloader.
		public var maxProgressSpeed:Number = 0.2;

		public function QueuedURLLoaderEvent(newUrlLoader:URLLoader, boundEvent:QueuedURLLoaderEvent, urlRequest:URLRequest) {
			super();
			if (!!newUrlLoader == !!boundEvent) throw new ArgumentError("QueuedURLLoaderEvent constructor must have either the first or second argument supplied and not both."); 
			
			_urlLoader = newUrlLoader;
			_boundEvent = boundEvent;
			_urlRequest = urlRequest;
			
			if (isFinishedLoading) {
				// Listeners might not have been added to this object yet, don't fire the complete sequence until a frame has passed.
				addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			} else {
				addListeners();
			}
		}
		private function enterFrameHandler(event:Event):void {
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			complete();
		}
		public function get urlRequest():URLRequest {
			return _urlRequest;
		}
		public function get urlLoader():URLLoader {
			if (_boundEvent && _boundEvent.urlLoader) {
				return _boundEvent.urlLoader;				
			} else {
				return _urlLoader;
			}	
		}
		private function addListeners():void {
			urlLoader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			urlLoader.addEventListener(Event.COMPLETE, loadCompleteHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		private function removeListeners():void {
			urlLoader.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			urlLoader.removeEventListener(Event.COMPLETE, loadCompleteHandler);
		}
		public function get isFinishedLoading():Boolean {
			var bytesLoaded:uint = urlLoader.bytesLoaded;
			var bytesTotal:uint = urlLoader.bytesTotal;
			if (bytesTotal == 0 || bytesLoaded < bytesTotal) {
				return false;
			} else {
				return true;
			}
		}
		override public function call():void {
			if (!_boundEvent) urlLoader.load(_urlRequest);
			super.call();
		}
		public function cancel():void {
			if (!isFinishedLoading) {
				try {
					urlLoader.close();
					if (_boundEvent) _boundEvent.cancel();
				} catch (ignore:Error) {}
			}
			if (preloader != null) {
				preloader.updateProgress(0, urlLoader.bytesTotal);
				preloader.hide();
			}
		}
		public function buildLoader():void {
			if (urlLoader.dataFormat == URLLoaderDataFormat.BINARY) {
				if (isFinishedLoading) {
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.INIT, loaderInitHandler);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loaderIoErrorHandler); 
					loader.loadBytes(urlLoader.data);
				} else {
					_buildLoader = true;
				}
			} else {
				throw new Error("Cannot call buildLoader() when urlLoader.dataFormat is not binary.");
			}
		}
		private function loaderInitHandler(event:Event):void {
			var loader:Loader = LoaderInfo(event.currentTarget).loader;
			dispatchEvent(new LoaderCreationEvent(loader, LoaderCreationEvent.LOADER_CREATION_COMPLETE));
		}
		private function loaderIoErrorHandler(event:Event):void {
			var loader:Loader = LoaderInfo(event.currentTarget).loader;
			dispatchEvent(new LoaderCreationEvent(loader, LoaderCreationEvent.LOADER_CREATION_ERROR));
		}
		
		/*
		 * Loader events
		 */
		protected function progressHandler(evt:ProgressEvent):void {
			if (preloader == null) return;
			var progressPercent:Number = evt.bytesLoaded / evt.bytesTotal;
			if (!showingPreloader && progressPercent < maxProgressSpeed) {
				preloader.show();
				showingPreloader = true;
			}
			preloader.updateProgress(evt.bytesLoaded, evt.bytesTotal);
		}
		protected function loadCompleteHandler(evt:Event):void {
			if (_buildLoader) buildLoader();
			complete();
			if (preloader) preloader.updateProgress(urlLoader.bytesLoaded, urlLoader.bytesTotal);
		}
		protected function ioErrorHandler(evt:IOErrorEvent):void {
			trace("URL: " + _urlRequest.url + " could not be found.");
			complete();
			removeListeners();
		}
		
	}
}