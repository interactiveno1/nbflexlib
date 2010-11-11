package com.nbilyk.layout {
	import mx.core.ILayoutElement;
	
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

		override public function measure():void {
			var totalWidth:Number = 0;
			var totalHeight:Number = 0;
			var layoutTarget:GroupBase = target;
			var n:int = layoutTarget.numElements;
			for (var i:int = 0; i < n; i++) {
				var element:ILayoutElement = useVirtualLayout ? layoutTarget.getVirtualElementAt(i) : layoutTarget.getElementAt(i);
				if (!element) element = typicalLayoutElement;
				var elementWidth:Number = element.getPreferredBoundsWidth();
				var elementHeight:Number = element.getPreferredBoundsHeight();
				totalWidth += elementWidth;
				totalHeight = Math.max(totalHeight, elementHeight);
			}
			if (n > 0) totalWidth += (n - 1) * horizontalGap;
			layoutTarget.measuredWidth = paddingLeft + totalWidth + paddingRight;
			layoutTarget.measuredHeight = paddingTop + totalHeight + paddingBottom;
			layoutTarget.measuredMinWidth = layoutTarget.measuredWidth ;
			layoutTarget.measuredMinHeight = layoutTarget.measuredHeight;
		}
		
		override public function updateDisplayList(containerWidth:Number, containerHeight:Number):void {
			var x:Number = paddingLeft;
			var y:Number = paddingTop;
			var availableWidth:Number = containerWidth - paddingLeft - paddingRight;

			var layoutTarget:GroupBase = target;
			var n:int = layoutTarget.numElements;
			var rowHeight:Number = 0;
			var rightBounds:Number = 0;
			for (var i:int = 0; i < n; i++) {
				var element:ILayoutElement = layoutTarget.getElementAt(i);
				element.setLayoutBoundsSize(NaN, NaN);

				var elementWidth:Number = element.getLayoutBoundsWidth();
				var elementHeight:Number = element.getLayoutBoundsHeight();
				rowHeight = Math.max(rowHeight, elementHeight);

				if (x + elementWidth > availableWidth) {
					x = paddingLeft;
					y += rowHeight + verticalGap;
					rowHeight = 0;
				}
				element.setLayoutBoundsPosition(x, y);
				x += elementWidth + horizontalGap;
				rightBounds = Math.max(x + elementWidth, rightBounds);
			}
			
			var h:Number = Math.ceil(y + rowHeight + paddingBottom);
			layoutTarget.setContentSize(Math.ceil(rightBounds + paddingRight), h);
			layoutTarget.measuredHeight = h;
		}
	}
}