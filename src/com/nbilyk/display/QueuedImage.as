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

	public class QueuedImage extends MovieClip {
		public static const IMAGE_REMOVE_BEGIN:String = "imageRemoveBegin";
		public static const IMAGE_REMOVE_COMPLETE:String = "imageRemoveComplete";
		public static const IMAGE_SHOW_BEGIN:String = "imageShowBegin";
		public static const IMAGE_SHOW_COMPLETE:String = "imageShowComplete";
		public static const IMAGE_LOAD_FAIL:String = "imageLoadFail";
		
		private var _isLoaded:Boolean = false;
		private var _hasErred:Boolean = false;
		private var _queuedLoaderEvent:QueuedUrlLoaderEvent;
		protected var _imageLoader:Loader;
		private var _preloader:IPreloader;
		
		// Config
		public var pixelSnapping:String = PixelSnapping.AUTO;
		public var smoothing:Boolean = false;
		public var useAnimations:Boolean = false; // TODO: Temp;
		
		// Images will load in the order set image is called, unless priority is set.
		public var tweenInParams:Object;
		public var tweenOutParams:Object;
		
		public var hAlign:int = 0;
		public static var LEFT:int = 0;
		public static var CENTER:int = 1;
		public static var RIGHT:int = 2;
		public var vAlign:int = 0;
		public static var TOP:int = 0;
		public static var MIDDLE:int = 1;
		public static var BOTTOM:int = 2;
		private var _image:String;
		private var _minWidth:Number;
		private var _minHeight:Number;
		private var _maxWidth:Number;
		private var _maxHeight:Number;
		
		private var logger:ILogger = Log.getLogger("com.nbilyk.display.QueuedImage");

		public function QueuedImage() {
			super();
			tweenInParams = { alpha:1, transition:"easeOut", time:.15 };
			tweenOutParams = { alpha:0, transition:"easeOut", time:.15 };
		}
		public function clear():void {
			if (!_queuedLoaderEvent.completed) {
				removeLoaderListeners();
				LoaderQueue.instance.removeLoaderEvent(_queuedLoaderEvent);
			} else {
				tweenOut(_imageLoader);
			}
			_queuedLoaderEvent = null;
		}
		public function load(urlRequest:URLRequest, priority:int = 0):void {
			_hasErred = false;
			_isLoaded = false;
			if (_queuedLoaderEvent) {
				clear();
			}
			_queuedLoaderEvent = LoaderQueue.instance.queueRequest(urlRequest, priority, _preloader);
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
			logger.info("Image: " + _queuedLoaderEvent.urlRequest.url + " has loaded.");
			_isLoaded = true;
			
			_imageLoader = event.loader;
			// Set pixelSnapping and smoothing on bitmap data.
			try {
				if (_imageLoader.contentLoaderInfo.childAllowsParent) {
					var bitmap:Bitmap = Bitmap(_imageLoader.contentLoaderInfo.content);
					bitmap.pixelSnapping = pixelSnapping;
					bitmap.smoothing = smoothing;
				} else {
					logger.info("Image requires policy file to make modifications.");
				}
			} catch (ignore:Error) {}
			
			draw();
			if (_preloader) _preloader.hide();
			tweenIn(_imageLoader);
			dispatchEvent(new Event(Event.COMPLETE));
		}
		private function loaderCreationErrorHandler(event:LoaderCreationEvent):void {
			logger.error("Image: " + _queuedLoaderEvent.urlRequest.url + " contained invalid data.");
			_hasErred = true;
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
		}
		private function ioErrorHandler(evt:IOErrorEvent):void {
			logger.error("Image: " + _queuedLoaderEvent.urlRequest.url + " could not be found.");
			_hasErred = true;
			dispatchEvent(new Event(IMAGE_LOAD_FAIL));
		}
		
		// Override the tween in/out functions to change the tween effects.
		protected function tweenIn(imageLoader:Loader):void {
			addChild(imageLoader);
			dispatchEvent(new Event(IMAGE_SHOW_BEGIN));
			if (useAnimations) {
				imageLoader.alpha = 0;
				tweenInParams.onComplete = tweenInMotionFinishedHandler;
				//Tweener.addTween(imageLoader, tweenInParams); 
			} else {
				imageLoader.alpha = 1;
				dispatchEvent(new Event(IMAGE_SHOW_COMPLETE));
			}
			drawNow();
		}
		protected function tweenInMotionFinishedHandler():void {
			dispatchEvent(new Event(IMAGE_SHOW_COMPLETE));
		}
		protected function tweenOut(imageLoader:Loader):void {
			dispatchEvent(new Event(IMAGE_REMOVE_BEGIN));
			if (useAnimations) {
				tweenOutParams.onCompleteParams = [imageLoader];
				tweenOutParams.onComplete = tweenOutMotionFinishHandler;
				//Tweener.addTween(imageLoader, tweenOutParams);
			} else {
				destroyLoader(imageLoader);
				dispatchEvent(new Event(IMAGE_REMOVE_COMPLETE));
			}
		}
		protected function tweenOutMotionFinishHandler(loaderToDestroy:Loader):void {
			destroyLoader(loaderToDestroy);
			dispatchEvent(new Event(IMAGE_REMOVE_COMPLETE));
		}
		protected function destroyLoader(loaderToDestroy:Loader):void {
			// Remove the imageLoader that has just now finished tweening out.
			try {
				removeChild(loaderToDestroy);
			} catch (err:Error) {
				logger.error(err.message);
			}
		}
		public function get imageLoader():Loader {
			return _imageLoader;
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
			if (_isLoaded) return _imageLoader.width;
			return -1;
		}
		public function get imageHeight():Number {
			if (_isLoaded) return _imageLoader.height;
			return -1;
		}
		public function get imageX():Number {
			return _imageLoader.x;
		}
		public function get imageY():Number {
			return _imageLoader.y;
		}
		public function get isLoaded():Boolean {
			return _isLoaded;
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
			if (_queuedLoaderEvent) _queuedLoaderEvent.preloader = value;
		}
		public function getBitmapData():BitmapData {
			if (_imageLoader && _imageLoader.contentLoaderInfo.childAllowsParent) {
				return Bitmap(_imageLoader.content).bitmapData.clone();
			} else {
				return null;
			}
			return null;
		}
		
		protected function draw():void {
			if (_isLoaded) {
				_imageLoader.scaleX = 1;
				_imageLoader.scaleY = 1;
				
				// Handle min dimensions
				if (minWidth && _imageLoader.width < minWidth) {
					_imageLoader.width = minWidth;
				}
				if (minHeight && _imageLoader.height < minHeight) {
					_imageLoader.height = minHeight;
				}
				if (minWidth || minHeight) {
					var largerScale:Number = Math.max(_imageLoader.scaleX, _imageLoader.scaleY);
					_imageLoader.scaleX = largerScale;
					_imageLoader.scaleY = largerScale;
				}
				// Handle max dimensions
				if (maxWidth && _imageLoader.width > maxWidth) {
					_imageLoader.width = maxWidth;
					_imageLoader.scaleY = _imageLoader.scaleX;
				}
				if (maxHeight && _imageLoader.height > maxHeight) {
					_imageLoader.height = maxHeight;
					_imageLoader.scaleX = _imageLoader.scaleY;
				}
				_imageLoader.x = 0;
				if (maxWidth) {
					if (hAlign == CENTER) {
						_imageLoader.x = maxWidth / 2 - _imageLoader.width / 2;
					} else if (hAlign == RIGHT) {
						_imageLoader.x = maxWidth - _imageLoader.width;
					}
				}
				_imageLoader.y = 0;
				if (maxHeight) {
					if (vAlign == MIDDLE) {
						_imageLoader.y = maxHeight / 2 - _imageLoader.height / 2;
					} else if (vAlign == BOTTOM) {
						_imageLoader.y = maxHeight - _imageLoader.height;
					}
				}
			}
		}
		public function drawNow():void {
			draw();
		}
		public function invalidate():void {
			var allowPass:Boolean = FunctionUtils.limit(invalidate);
			if (!allowPass) return;
			draw();
		}
	}
}
