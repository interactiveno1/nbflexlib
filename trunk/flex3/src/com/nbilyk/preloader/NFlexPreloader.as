package com.nbilyk.preloader {
	import mx.events.FlexEvent;
	import mx.events.RSLEvent;
	import mx.preloaders.IPreloaderDisplay;

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	/**
	 * NFlexPreloader is a replacement to the flex DownloadProgressBar class.
	 * This is an abstract class that has no view.  To use this class, extend it,
	 * then override the createChildren and optionally the layout method.
	 * 
	 * e.g.
	 * 
	 * [Embed(source="/defaultPreloader.swf", symbol="PreloaderGfx")]
	 * private var PreloaderGfx:Class;
	 * 
	 * override protected function createChildren():void {
	 *   var preloaderGfx:MovieClip = new PreloaderGfx() as MovieClip;
	 *   if (preloaderGfx) {
	 *     preloaderGfx.visible = false;
	 *	   preloaderController.view = preloaderGfx;
	 *	   addChild(preloaderGfx);
	 *     layout();
	 *   }
	 * }
	 */
	public class NFlexPreloader extends Sprite implements IPreloaderDisplay {

		/**
		 *  The string to display as the label while in the initializing phase.
		 *
		 *  @default "Initializing"
		 */
		public static var initializingLabel:String = "Initializing";
		
		/**
		 *  The string to display as the label while in the downloading phase.
		 *
		 *  @default "Loading"
		 */
		public static var downloadingLabel:String = "Loading";
		
		/**
		 *  The minimum number of milliseconds
		 *  that the display should appear visible.
		 *  If the downloading and initialization of the application
		 *  takes less time than this value, then Flex pauses for this amount
		 *  of time before dispatching the <code>complete</code> event.
		 *
		 *  @default 0
		 */
		protected var minimumDisplayTime:uint = 1000;

		/**
		 *  The percentage of the progress bar that the downloading phase
		 *  fills when the SWF file is fully downloaded.
		 *  The rest of the progress bar is filled during the initializing phase.
		 *  This should be a value from 0 to 1.
		 *
		 *  @default 60
		 */
		protected var downloadPercent:Number = 0.6;
		
		/**
		 * If the Flex preloading isn't 100% of the preloading your application needs to do, 
		 * you can set this to less than 1 to scale the progress down.
		 * 
		 * This should be a value from 0 to 1
		 */
		protected var maxPercent:Number = 1;

		private var _total:Number = 0;
		private var _loaded:Number = 0;
		
		private var _startTime:int;
		private var _displayTime:int;
		private var _startedLoading:Boolean = false;
		private var _startedInit:Boolean = false;
		private var _showingDisplay:Boolean = false;
		private var _displayStartCount:uint = 0;
		private var _initProgressCount:uint = 0;
		private var _initProgressTotal:uint = 12;

		private var _visible:Boolean = false;
		private var _backgroundAlpha:Number = 1;
		private var _backgroundColor:uint;
		private var _backgroundImage:Object;
		private var _backgroundSize:String = "";
		private var _stageHeight:Number = 375;
		private var _stageWidth:Number = 500;
		private var _label:String;
		
		// Stage instances
		protected var preloaderController:NPreloaderController;
		private var _preloader:Sprite; // Type Preloader
		
		public function NFlexPreloader() {
			super();
			preloaderController = new NPreloaderController();
		}
		
		//--------------------------------------------------------------------------
		//  IPreloaderDisplay methods
		//--------------------------------------------------------------------------

		/**
		 *  Alpha level of the SWF file or image defined by
		 *  the <code>backgroundImage</code> property, or the color defined by
		 *  the <code>backgroundColor</code> property.
		 *  Valid values range from 0 to 1.0.
		 *
		 *  <p>You can specify either a <code>backgroundColor</code>
		 *  or a <code>backgroundImage</code>, but not both.</p>
		 *
		 *  @default 1.0
		 *
		 */
		public function get backgroundAlpha():Number {
			if (!isNaN(_backgroundAlpha))
				return _backgroundAlpha;
			else
				return 1;
		}

		public function set backgroundAlpha(value:Number):void {
			_backgroundAlpha = value;
		}


		/**
		 *  Background color of a download progress bar.
		 *  You can have either a <code>backgroundColor</code> or a
		 *  <code>backgroundImage</code>, but not both.
		 */
		public function get backgroundColor():uint {
			return _backgroundColor;
		}

		public function set backgroundColor(value:uint):void {
			_backgroundColor = value;
		}


		/**
		 *  The background image of the application,
		 *  which is passed in by the preloader.
		 *  You can specify either a <code>backgroundColor</code>
		 *  or a <code>backgroundImage</code>, but not both.
		 *
		 *  <p>A value of null means "not set".
		 *  If this style and the <code>backgroundColor</code> style are undefined,
		 *  the component has a transparent background.</p>
		 *
		 *  <p>The preloader does not display embedded images.
		 *  You can only use images loaded at runtime.</p>
		 *
		 *  @default null
		 */
		public function get backgroundImage():Object {
			return _backgroundImage;
		}

		/**
		 *  @private
		 */
		public function set backgroundImage(value:Object):void {
			_backgroundImage = value;
		}

		/**
		 *  Scales the image specified by <code>backgroundImage</code>
		 *  to different percentage sizes.
		 *  A value of <code>"100%"</code> stretches the image
		 *  to fit the entire component.
		 *  To specify a percentage value, you must include the percent sign (%).
		 *  A value of <code>"auto"</code>, maintains
		 *  the original size of the image.
		 *
		 *  @default "auto"
		 */
		public function get backgroundSize():String {
			return _backgroundSize;
		}

		public function set backgroundSize(value:String):void {
			_backgroundSize = value;
		}

		/**
		 *  The Preloader class passes in a reference to itself to the display class
		 *  so that it can listen for events from the preloader.
		 */
		public function set preloader(value:Sprite):void {
			if (_preloader) return; // This can only be set once.
			_preloader = value;

			value.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			value.addEventListener(Event.COMPLETE, completeHandler);

			value.addEventListener(RSLEvent.RSL_PROGRESS, rslProgressHandler);
			value.addEventListener(RSLEvent.RSL_COMPLETE, rslCompleteHandler);
			value.addEventListener(RSLEvent.RSL_ERROR, rslErrorHandler);

			value.addEventListener(FlexEvent.INIT_PROGRESS, initProgressHandler);
			value.addEventListener(FlexEvent.INIT_COMPLETE, initCompleteHandler);
		}

		/**
		 *  The height of the stage,
		 *  which is passed in by the Preloader class.
		 */
		public function get stageHeight():Number {
			return _stageHeight;
		}

		public function set stageHeight(value:Number):void {
			_stageHeight = value;
		}

		/**
		 *  The width of the stage,
		 *  which is passed in by the Preloader class.
		 */
		public function get stageWidth():Number {
			return _stageWidth;
		}

		public function set stageWidth(value:Number):void {
			_stageWidth = value;
		}
		
		/**
		 *  Called by the Preloader after the download progress bar
		 *  has been added as a child of the Preloader.
		 *  This should be the starting point for configuring your download progress bar.
		 */
		public function initialize():void {
			_startTime = getTimer();
			createChildren();
		}
		
		protected function createChildren():void {
		}
		
		//-----------------------------------------
		// Getters / setters
		//-----------------------------------------
		
		override public function get visible():Boolean {
			return _visible;
		}
		
		override public function set visible(value:Boolean):void {
			if (!_visible && value)
				show();
				
			else if (_visible && !value)
				hide();
			
			_visible = value;
		}

		/**
		 *  Text to display when the progress bar is active.
		 *  The Preloader class sets this value
		 *  before displaying the progress bar.
		 *  Implementing this property in a subclass is optional.
		 *
		 *  @default ""
		 */
		protected function get label():String {
			return _label;
		}

		protected function set label(value:String):void {
			_label = value;
			draw();
		}

		/**
		 *  Updates the display of the download progress bar
		 *  with the current download information.
		 *  A typical implementation divides the loaded value by the total value
		 *  and displays a percentage.
		 *  If you do not implement this method, you should create
		 *  a progress bar that displays an animation to indicate to the user
		 *  that a download is occurring.
		 *
		 *  <p>The <code>setProgress()</code> method is only called
		 *  if the application is being downloaded from a remote server
		 *  and the application is not in the browser cache.</p>
		 *
		 *  @param completed Number of bytes of the application SWF file
		 *  that have been downloaded.
		 *
		 *  @param total Size of the application SWF file in bytes.
		 */
		protected function setProgress(completed:Number, total:Number):void {
			if (!isNaN(completed) && !isNaN(total) && completed >= 0 && total > 0) {
				_loaded = Number(completed);
				_total = Number(total);
				draw();
			}
		}

		/**
		 *  Returns the percentage value of the application loaded.
		 *
		 *  @param loaded Number of bytes of the application SWF file
		 *  that have been downloaded.
		 *
		 *  @param total Size of the application SWF file in bytes.
		 *
		 *  @return The percentage value of the loaded application.
		 */
		protected function getPercentLoaded(loaded:Number, total:Number):Number {
			var perc:Number;

			if (loaded == 0 || total == 0 || isNaN(total) || isNaN(loaded))
				return 0;
			else
				perc = loaded / total;

			if (isNaN(perc) || perc <= 0)
				return 0;
			else if (perc > 0.99)
				return 0.99;
			else
				return perc;
		}

		/**
		 *  @private
		 *  Make the display class visible.
		 */
		private function show():void {
			_showingDisplay = true;
			draw();
			_displayTime = getTimer(); // Time when the display is shown.
		}

		/**
		 *  @private
		 */
		private function hide():void {
		}


		/**
		 *  Defines the algorithm for determining whether to show the download progress bar
		 *  while in the initialization phase, assuming that the display
		 *  is not currently visible.
		 *
		 *  @param elapsedTime number of milliseconds that have elapsed
		 *  since the start of the download phase.
		 *
		 *  @param count number of times that the <code>initProgress</code> event
		 *  has been received from the application.
		 *
		 *  @return If <code>true</code>, then show the download progress bar.
		 */
		protected function showDisplayForInit(elapsedTime:int, count:int):Boolean {
			return elapsedTime > 300 && count == 2;
		}


		//------------------------------------
		// Validation / invalidation
		//------------------------------------
		
		/**
		 *  @private
		 *  Updates the display.
		 */
		protected function draw():void {
			var percentage:Number;
			
			if (_startedLoading) {
				if (!_startedInit) {
					// 0 to downloadPercentage
					percentage = getPercentLoaded(_loaded, _total) * downloadPercent;
				} else {
					// downloadPercentage to 100
					percentage = getPercentLoaded(_loaded, _total) * (1 - downloadPercent) + downloadPercent;
				}
			} else {
				percentage = getPercentLoaded(_loaded, _total);
			}
			percentage *= maxPercent;
			
			preloaderController.percent = percentage;
			layout();
		}
		
		protected function layout():void {
			var v:MovieClip = preloaderController.view;
			if (v) {
				v.x = (stageWidth - v.width) / 2;
				v.y = (stageHeight - v.height) / 2;
			}
		}

		//--------------------------------------------------------------------------
		//  Event handlers
		//--------------------------------------------------------------------------

		/**
		 *  Event listener for the <code>ProgressEvent.PROGRESS</code> event.
		 *  This implementation updates the progress bar
		 *  with the percentage of bytes downloaded.
		 *
		 *  @param event The event object.
		 */
		protected function progressHandler(event:ProgressEvent):void {
			// Only show the Loading phase if it will appear for awhile.
			if (_showingDisplay) {
				if (!_startedLoading) {
					show();
					label = downloadingLabel;
					_startedLoading = true;
				}

				setProgress(event.bytesLoaded, event.bytesTotal);
			}
		}

		/**
		 *  Event listener for the <code>Event.COMPLETE</code> event.
		 *  The default implementation does nothing.
		 *
		 *  @param event The event object.
		 */
		protected function completeHandler(event:Event):void {
		}

		/**
		 *  Event listener for the <code>RSLEvent.RSL_PROGRESS</code> event.
		 *  The default implementation does nothing.
		 *
		 *  @param event The event object.
		 */
		protected function rslProgressHandler(event:RSLEvent):void {
		}

		/**
		 *  Event listener for the <code>RSLEvent.RSL_COMPLETE</code> event.
		 *
		 *  @param event The event object.
		 */
		protected function rslCompleteHandler(event:RSLEvent):void {
			label = "Loaded library " + event.rslIndex + " of " + event.rslTotal;
		}

		/**
		 *  Event listener for the <code>RSLEvent.RSL_ERROR</code> event.
		 *  This event listener handles any errors detected when downloading an RSL.
		 *
		 *  @param event The event object.
		 */
		protected function rslErrorHandler(event:RSLEvent):void {
			_preloader.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
			_preloader.removeEventListener(Event.COMPLETE, completeHandler);
			
			_preloader.removeEventListener(RSLEvent.RSL_PROGRESS, rslProgressHandler);
			_preloader.removeEventListener(RSLEvent.RSL_COMPLETE, rslCompleteHandler);
			_preloader.removeEventListener(RSLEvent.RSL_ERROR, rslErrorHandler);
			
			_preloader.removeEventListener(FlexEvent.INIT_PROGRESS, initProgressHandler);
			_preloader.removeEventListener(FlexEvent.INIT_COMPLETE, initCompleteHandler);

			if (!_showingDisplay) {
				show();
				_showingDisplay = true;
			}

			label = "RSL Error " + (event.rslIndex + 1) + " of " + event.rslTotal;

			var errorField:ErrorField = new ErrorField();
			errorField.show(event.errorText, stageWidth, stageHeight);
			addChild(errorField);
		}

		/**
		 *  Event listener for the <code>FlexEvent.INIT_PROGRESS</code> event.
		 *
		 *  @param event The event object.
		 */
		protected function initProgressHandler(event:Event):void {
			var elapsedTime:int = getTimer() - _startTime;
			_initProgressCount++;

			if (!_showingDisplay && showDisplayForInit(elapsedTime, _initProgressCount)) {
				_displayStartCount = _initProgressCount;
				show();
			} else if (_showingDisplay) {
				if (!_startedInit) {
					// First init progress event.
					_startedInit = true;
					label = initializingLabel;
				}

				var loaded:Number = 100 * _initProgressCount / (_initProgressTotal - _displayStartCount);
				setProgress(loaded, 100);
			}
		}

		/**
		 *  @private
		 */
		private function initCompleteHandler(event:Event):void {
			var elapsedTime:int = getTimer() - _displayTime;

			if (_showingDisplay && elapsedTime < minimumDisplayTime) {
				setTimeout(dispatchEvent, minimumDisplayTime - elapsedTime, new Event(Event.COMPLETE));
			} else {
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
	}

}

import com.nbilyk.preloader.NFlexPreloader;

import flash.display.Sprite;
import flash.system.Capabilities;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

/**
 * Area to display error messages to help debug startup problems.
 */
class ErrorField extends Sprite {
	private var downloadProgressBar:NFlexPreloader;
	private const MIN_WIDTH_INCHES:int = 2; // min width of error message in inches
	private const MAX_WIDTH_INCHES:int = 6; // max width of error message in inches
	private const TEXT_MARGIN_PX:int = 10;


	//----------------------------------
	//  labelFormat
	//----------------------------------

	/**
	 *  The TextFormat object of the TextField component of the label.
	 *  This is a read-only property which you must override
	 *  if you need to change it.
	 */
	protected function get labelFormat():TextFormat {
		var tf:TextFormat = new TextFormat();
		tf.color = 0x000000;
		tf.font = "Verdana";
		tf.size = 10;
		return tf;
	}


	/**
	 * @private
	 *
	 * @param - parent - parent of the error field.
	 */
	public function ErrorField() {
		super();
	}


	/**
	 * Create and show the error message.
	 *
	 * @param errorText - text for error message.
	 */
	public function show(errorText:String, stageWidth:Number, stageHeight:Number):void {
		if (errorText == null || errorText.length == 0)
			return;

		// create the text field for the message and 
		// add it to the parent.
		var textField:TextField = new TextField();

		textField.autoSize = TextFieldAutoSize.LEFT;
		textField.multiline = true;
		textField.wordWrap = true;
		textField.background = true;
		textField.defaultTextFormat = labelFormat;
		textField.text = errorText;

		textField.width = Math.max(MIN_WIDTH_INCHES * Capabilities.screenDPI, stageWidth - (TEXT_MARGIN_PX * 2));
		textField.width = Math.min(MAX_WIDTH_INCHES * Capabilities.screenDPI, textField.width);
		textField.y = Math.max(0, stageHeight - TEXT_MARGIN_PX - textField.height);

		// center field horizontally
		textField.x = (stageWidth - textField.width) / 2;

		downloadProgressBar.parent.addChild(this);
		addChild(textField);

	}
}
