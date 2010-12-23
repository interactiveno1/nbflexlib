package com.nbilyk.layout {
	import flash.utils.setTimeout;
	
	import mx.core.ILayoutElement;
	import mx.core.UIComponent;
	import mx.managers.ILayoutManager;
	import mx.managers.ILayoutManagerClient;
	import mx.managers.LayoutManager;
	
	import spark.components.supportClasses.GroupBase;
	import spark.layouts.supportClasses.LayoutBase;

	/**
	 * Thanks to evtimmy
	 * http://evtimmy.com/2009/06/flowlayout-a-spark-custom-layout-example/
	 */
	public class FlowLayout extends LayoutBase {
		
		public var paddingLeft:Number = 0;
		public var paddingTop:Number = 0;
		public var paddingRight:Number = 0;
		public var paddingBottom:Number = 0;
		public var horizontalGap:Number = 5;
		public var verticalGap:Number = 5;
		
		private var previousContainerWidth:Number = Number.MAX_VALUE;
		private var previousMeasuredHeight:Number = Number.MAX_VALUE;

		override public function measure():void {
			layout(previousContainerWidth, false);
		}
		
		override public function updateDisplayList(containerWidth:Number, containerHeight:Number):void {
			layout(containerWidth, true);
		}
		
		protected function layout(containerWidth:Number, update:Boolean):void {
			var x:Number = paddingLeft;
			var y:Number = paddingTop;
			var availableWidth:Number = containerWidth - paddingLeft - paddingRight;
			
			var layoutTarget:GroupBase = target;
			var n:int = layoutTarget.numElements;
			if (!n) return;
			var rowHeight:Number = 0;
			var rightBounds:Number = paddingLeft;
			var bottomBounds:Number = paddingTop;
			var largestItemWidth:Number = 0;
			var largestItemHeight:Number = 0;
			for (var i:int = 0; i < n; i++) {
				var element:ILayoutElement = layoutTarget.getElementAt(i);
				element.setLayoutBoundsSize(NaN, NaN);
				if (!element.includeInLayout) continue;
				
				var elementWidth:Number = element.getLayoutBoundsWidth();
				var elementHeight:Number = element.getLayoutBoundsHeight();
				rowHeight = Math.max(rowHeight, elementHeight);
				
				if (x + elementWidth > availableWidth) {
					x = paddingLeft;
					y += rowHeight + verticalGap;
					rowHeight = 0;
				}
				if (update) element.setLayoutBoundsPosition(x, y);
				rightBounds = Math.max(x + elementWidth, rightBounds);
				bottomBounds = Math.max(y + elementHeight, bottomBounds);
				largestItemWidth = Math.max(largestItemWidth, elementWidth);
				largestItemHeight = Math.max(largestItemHeight, elementHeight);
				x += elementWidth + horizontalGap;
			}
			
			var w:Number = Math.ceil(rightBounds + paddingRight);
			var h:Number = Math.ceil(bottomBounds + paddingBottom);
			if (update) {
				layoutTarget.setContentSize(w, h);
				if (containerWidth != previousContainerWidth || h != previousMeasuredHeight) {
					previousContainerWidth = containerWidth;
					if (layoutTarget.parent is ILayoutManagerClient) {
						layoutTarget.callLater(measure);
						layoutTarget.callLater(UIComponent(layoutTarget.parent).invalidateSize);
						
					}
				}
			} else {
				layoutTarget.measuredWidth = w;
				layoutTarget.measuredMinWidth = Math.ceil(paddingLeft + largestItemWidth + paddingRight);
				layoutTarget.measuredHeight = h;
				layoutTarget.measuredMinHeight = 0;
				previousMeasuredHeight = h;
			}
		}
	}
}