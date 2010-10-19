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
		
		override public function updateDisplayList(containerWidth:Number, containerHeight:Number):void {
			var x:Number = paddingLeft;
			var y:Number = paddingTop;
			var availableWidth:Number = containerWidth - paddingLeft - paddingRight;

			var layoutTarget:GroupBase = target;
			var n:int = layoutTarget.numElements;
			for (var i:int = 0; i < n; i++) {
				var element:ILayoutElement = layoutTarget.getElementAt(i);
				element.setLayoutBoundsSize(NaN, NaN);

				var elementWidth:Number = element.getLayoutBoundsWidth();
				var elementHeight:Number = element.getLayoutBoundsHeight();

				if (x + elementWidth > availableWidth) {
					x = paddingLeft;
					y += elementHeight + verticalGap;
				}
				element.setLayoutBoundsPosition(x, y);
				x += elementWidth + horizontalGap;
			}
		}
	}
}