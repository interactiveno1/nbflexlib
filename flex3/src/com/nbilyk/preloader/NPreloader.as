package com.nbilyk.preloader {
	import flash.display.MovieClip;
	
	import mx.core.UIComponent;

	[Style(name="preloaderView", type="Class")]
	public class NPreloader extends UIComponent {
		
		private var controller:NPreloaderController = new NPreloaderController();
		
		public function NPreloader() {
			super();
		}

		/**
		 *  @private
		 */
		override public function styleChanged(styleProp:String):void {
			super.styleChanged(styleProp);
			var allStyles:Boolean = styleProp == null || styleProp == "styleName";

			if (allStyles || styleProp == "preloaderView") {
				createPreloaderView();
				invalidateDisplayList();
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			createPreloaderView();
		}
		
		protected function createPreloaderView():void {
			var preloaderClass:Class = getStyle("preloaderView") as Class;
			if (preloaderClass) {
				var preloaderView:MovieClip = new preloaderClass() as MovieClip;
				if (preloaderView) {
					controller.view = preloaderView;
					addChild(preloaderView);
				}
			}
		}
		
		override protected function measure():void {
			super.measure();
			var v:MovieClip = controller.view;
			if (v) {
				measuredWidth = v.width;
				measuredHeight = v.height;
			}
		}
		
		//---------------------------------
		// Getters / setters
		//---------------------------------
		
		public function get percent():Number {
			return controller.percent;
		}
		
		public function set percent(value:Number):void {
			controller.percent = value;
		}
	}
}