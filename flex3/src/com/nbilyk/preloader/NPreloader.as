package com.nbilyk.preloader {
	import flash.display.MovieClip;
	
	import mx.core.UIComponent;

	[Style(name="preloaderView", type="Class")]
	[Style(name="indeterminateView", type="Class")]
	[ResourceBundle("nbflexlib")]
	public class NPreloader extends UIComponent {
		
		private var _preloaderClass:Class;
		
		private var controller:NPreloaderController = new NPreloaderController();
		private var labelExplicitlySet:Boolean;
		
		public function NPreloader() {
			super();
			resourcesChanged();
		}

		/**
		 *  @private
		 */
		override public function styleChanged(styleProp:String):void {
			super.styleChanged(styleProp);
			var allStyles:Boolean = styleProp == null || styleProp == "styleName";

			if (allStyles || styleProp == "preloaderView" || styleProp == "indeterminateView") {
				createPreloaderView();
				invalidateDisplayList();
			}
		}
		
		override protected function resourcesChanged():void {
			super.resourcesChanged();
			
			if (!labelExplicitlySet) {
				if (indeterminate) controller.label = resourceManager.getString("nbflexlib", "npreloader.label");
				else controller.label = resourceManager.getString("nbflexlib", "npreloader.indeterminateLabel");
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			createPreloaderView();
		}
		
		protected function createPreloaderView():void {
			if (indeterminate) {
				preloaderClass = getStyle("indeterminateView") as Class;
			} else {
				preloaderClass = getStyle("preloaderView") as Class;
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

		public function get indeterminate():Boolean {
			return controller.indeterminate;
		}

		public function set indeterminate(value:Boolean):void {
			if (controller.indeterminate == value) return; // no-op
			controller.indeterminate = value;
			createPreloaderView();
			resourcesChanged();
		}

		public function get preloaderClass():Class {
			return _preloaderClass;
		}

		public function set preloaderClass(value:Class):void {
			if (_preloaderClass == value) return; // no-op
			
			if (controller.view) {
				removeChild(controller.view);
				controller.view = null;
			}
			
			_preloaderClass = value;
			
			if (_preloaderClass) {
				var preloaderView:MovieClip = new _preloaderClass() as MovieClip;
				controller.view = preloaderView;
				if (preloaderView) {
					addChild(preloaderView);
				}
			}
		}

		public function get label():String {
			return controller.label;
		}

		public function set label(value:String):void {
			controller.label = value;
			labelExplicitlySet = true;
		}

	}
}