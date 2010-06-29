/*
   Copyright (c) 2007, 2008 Nicholas Bilyk
 */

package com.nbilyk.display {
	import com.nbilyk.events.LoaderCreationEvent;
	import com.nbilyk.events.QueuedUrlLoaderEvent;
	import com.nbilyk.utils.FunctionUtils;
	import com.nbilyk.utils.LoaderQueue;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	[Event(name="complete", type="flash.events.Event")]
	[Event(name="imageLoadFail", type="flash.events.Event")]
	public class QueuedImage extends MovieClip {
		public static const IMAGE_LOAD_FAIL:String = "imageLoadFail";



		public static var LEFT:int = 0;
		public static var CENTER:int = 1;
		public static var RIGHT:int = 2;
		public static var TOP:int = 0;
		public static var MIDDLE:int = 1;
		public static var BOTTOM:int = 2;
		
		// Config
		public var pixelSnapping:String = PixelSnapping.AUTO;
		public var smoothing:Boolean = false;
		public var useAnimations:Boolean = false; // TODO: Temp;
		
		public var vAlign:int = 0;
		public var hAlign:int = 0;
		
		protected var loaderQueue:LoaderQueue;
		
		private var _imageLoader:Loader;
		private var _isLoaded:Boolean = false;
		private var _hasErred:Boolean = false;
		private var _queuedLoaderEvent:QueuedUrlLoaderEvent;
		private var _preloader:IPreloader;
		
		private var _image:String;
		private var _minWidth:Number;
		private var _minHeight:Number;
		private var _maxWidth:Number;
		private var _maxHeight:Number;

		private var logger:ILogger = Log.getLogger("com.nbilyk.display.QueuedImage");

		public function QueuedImage(loaderQueueVal:LoaderQueue) {
			super();
			loaderQueue = loaderQueueVal;
		}

		public function clear():void {
			if (!_queuedLoaderEvent.completed) {
				removeLoaderListeners();
				loaderQueue.removeLoaderEvent(_queuedLoaderEvent);
			} else {
				try {
					if (imageLoader && imageLoader.parent) removeChild(imageLoader);
				} catch (err:Error) {
					logger.error(err.message);
				}
			}
			_queuedLoaderEvent = null;
		}

		public function load(urlRequest:URLRequest, priority:int = 0):void {
			_hasErred = false;
			setIsLoaded(false);
			if (_queuedLoaderEvent) {
				clear();
			}
			_queuedLoaderEvent = loaderQueue.queueRequest(urlRequest, priority, preloader);
			addLoaderListeners();
			_queuedLoaderEvent.buildLoader();
		}

		public function cancel():void {
			_queuedLoaderEvent.cancel();
		}

		protected function addLoaderListeners():void {
			_queuedLoaderEvent.addEventListener(Event.CANCEL, loadingCancelHandler);
			_queuedLoaderEvent.addEventListener(LoaderCreationEvent.LOADER_CREATION_COMPLETE, loaderCreationCompleteHandler);
			_queuedLoaderEvent.addEventListener(LoaderCreationEvent.LOADER_CREATION_ERROR, loaderCreationErrorHandler);
			_queuedLoaderEvent.urlLoader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}

		protected function removeLoaderListeners():void {
			_queuedLoaderEvent.removeEventListener(Event.CANCEL, loadingCancelHandler);
			_queuedLoaderEvent.removeEventListener(LoaderCreationEvent.LOADER_CREATION_COMPLETE, loaderCreationCompleteHandler);
			_queuedLoaderEvent.urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}

		protected function loadingCancelHandler(event:Event):void {
			dispatchEvent(new Event(Event.CANCEL));
		}

		protected function loaderCreationCompleteHandler(event:LoaderCreationEvent):void {
			setIsLoaded(true);

			setImageLoader(event.loader);
			// Set pixelSnapping and smoothing on bitmap data.
			try {
				if (imageLoader.contentLoaderInfo.childAllowsParent) {
					var bitmap:Bitmap = Bitmap(imageLoader.contentLoaderInfo.content);
					bitmap.pixelSnapping = pixelSnapping;
					bitmap.smoothing = smoothing;
				} else {
					logger.info("Image requires policy file to make modifications.");
				}
			} catch (ignore:Error) {
			}

			draw();
			if (preloader) preloader.hide();
			addChild(imageLoader);
			dispatchEvent(new Event(Event.COMPLETE));
		}

		private function loaderCreationErrorHandler(event:LoaderCreationEvent):void {
			logger.error("Image: " + _queuedLoaderEvent.urlRequest.url + " contained invalid data.");
			_hasErred = true;
			dispatchEvent(new Event(IMAGE_LOAD_FAIL));
		}

		private function ioErrorHandler(evt:IOErrorEvent):void {
			logger.error("Image: " + _queuedLoaderEvent.urlRequest.url + " could not be found.");
			_hasErred = true;
			dispatchEvent(new Event(IMAGE_LOAD_FAIL));
		}
		
		//-------------------------------
		// Validation / invalidation
		//-------------------------------
		
		public function invalidate():void {
			var allowPass:Boolean = FunctionUtils.limit(invalidate);
			if (!allowPass)
				return;
			draw();
		}

		protected function draw():void {
			var iL:Loader = imageLoader;
			if (isLoaded) {
				iL.scaleX = 1;
				iL.scaleY = 1;

				// Handle min dimensions
				if (minWidth && iL.width < minWidth) {
					iL.width = minWidth;
				}
				if (minHeight && iL.height < minHeight) {
					iL.height = minHeight;
				}
				if (minWidth || minHeight) {
					var largerScale:Number = Math.max(iL.scaleX, iL.scaleY);
					iL.scaleX = largerScale;
					iL.scaleY = largerScale;
				}
				// Handle max dimensions
				if (maxWidth && iL.width > maxWidth) {
					iL.width = maxWidth;
					iL.scaleY = iL.scaleX;
				}
				if (maxHeight && iL.height > maxHeight) {
					iL.height = maxHeight;
					iL.scaleX = iL.scaleY;
				}
				iL.x = 0;
				if (maxWidth) {
					if (hAlign == CENTER) {
						iL.x = maxWidth / 2 - iL.width / 2;
					} else if (hAlign == RIGHT) {
						iL.x = maxWidth - iL.width;
					}
				}
				iL.y = 0;
				if (maxHeight) {
					if (vAlign == MIDDLE) {
						iL.y = maxHeight / 2 - iL.height / 2;
					} else if (vAlign == BOTTOM) {
						iL.y = maxHeight - iL.height;
					}
				}
			}
		}
		
		//-----------------------
		// Getters / setters
		//-----------------------

		public function get imageLoader():Loader {
			return _imageLoader;
		}
		
		protected function setImageLoader(value:Loader):void {
			_imageLoader = value;
		}

		public function get minWidth():Number {
			return _minWidth;
		}

		public function set minWidth(value:Number):void {
			_minWidth = value;
			invalidate();
		}

		public function get minHeight():Number {
			return _minHeight;
		}

		public function set minHeight(value:Number):void {
			_minHeight = value;
			invalidate();
		}

		public function get maxWidth():Number {
			return _maxWidth;
		}

		public function set maxWidth(value:Number):void {
			_maxWidth = value;
			invalidate();
		}

		public function get maxHeight():Number {
			return _maxHeight;
		}

		public function set maxHeight(value:Number):void {
			_maxHeight = value;
			invalidate();
		}

		public function get imageWidth():Number {
			if (isLoaded)
				return imageLoader.width;
			return -1;
		}

		public function get imageHeight():Number {
			if (isLoaded)
				return imageLoader.height;
			return -1;
		}

		public function get imageX():Number {
			return imageLoader.x;
		}

		public function get imageY():Number {
			return imageLoader.y;
		}

		public function get isLoaded():Boolean {
			return _isLoaded;
		}
		
		protected function setIsLoaded(value:Boolean):void {
			_isLoaded = value;
		}

		public function get hasErred():Boolean {
			return _hasErred;
		}

		public function get image():String {
			return _image;
		}

		public function get preloader():IPreloader {
			return _preloader;
		}

		public function set preloader(value:IPreloader):void {
			_preloader = value;
			if (_queuedLoaderEvent)
				_queuedLoaderEvent.preloader = value;
		}

		public function getBitmapData():BitmapData {
			if (imageLoader && imageLoader.contentLoaderInfo.childAllowsParent) {
				return Bitmap(imageLoader.content).bitmapData.clone();
			} else {
				return null;
			}
			return null;
		}
	}
}
