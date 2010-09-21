package com.nbilyk.preloader {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;

	/**
	 * NPreloaderController is a wrapper to a view MovieClip to play the MovieClip 
	 * and stop where the current frame divided by the total frames is equal to
	 * the progress set.
	 */
	public class NPreloaderController {

		/**
		 * Text that accompanies the progress bar. You can include
		 * the following special characters in the text string:
		 *
		 * <ul>
		 *   <li>%3 = percent loaded</li>
		 *   <li>%% = "%" character</li>
		 * </ul>
		 *
		 * Note: NPreloader does not support bytesLoaded or bytesTotal.
		 * 
		 * @default "%3%% LOADED"
		 */
		public var label:String = "%3%% LOADED";
		
		/**
		 * If indeterminate is true, percent is ignored and the view MovieClip will play indefinitely.
		 */
		public var indeterminate:Boolean;
		
		private var _view:MovieClip;
		private var _percent:Number = 0;
		private var _isPlaying:Boolean;
		
		/**
		 * The field name of the TextField on the view MovieClip of which to set the label.
		 */
		private var labelField:String = "text";
		
		public function NPreloaderController() {
			super();
		}

		public function get view():MovieClip {
			return _view;
		}

		public function set view(value:MovieClip):void {
			if (_view) {
				_view.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
			_view = value;
			if (_view) {
				_view.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
				_view.stop();
				_isPlaying = false;
			}
		}

		public function get percent():Number {
			return _percent;
		}

		public function set percent(value:Number):void {
			value = Math.max(0, Math.min(1, value));
			_percent = value;
		}
		
		private function enterFrameHandler(event:Event):void {
			var currentPercent:Number = view.currentFrame / view.totalFrames;
			isPlaying = indeterminate || currentPercent < percent;
			
			if (view.hasOwnProperty(labelField)) {
				// Set the label
				var tF:TextField = view[labelField] as TextField;
				if (tF) {
					var labelText:String = label || "";
					labelText = labelText.replace("%3", String(Math.floor(currentPercent * 100)));
					labelText = labelText.replace("%%", "%");
					tF.text = labelText;
				}
			}
		}

		public function get isPlaying():Boolean {
			return _isPlaying;
		}

		public function set isPlaying(value:Boolean):void {
			if (_isPlaying == value) return; // no-op
			_isPlaying = value;
			if (_view) {
				if (value) _view.play();
				else _view.stop();
			}
		}
	}
}