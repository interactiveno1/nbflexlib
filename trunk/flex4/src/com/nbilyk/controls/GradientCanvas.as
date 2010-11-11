package com.nbilyk.controls {
	import com.nbilyk.utils.StyleUtil;
	
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;

	[Style(name="gradientFillColors", type="Array", inherit="no")]
	[Style(name="gradientFillAlphas", type="Array", inherit="no")]
	[Style(name="gradientFillRatios", type="Array", inherit="no")]
	public class GradientCanvas extends Canvas {
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			StyleUtil.drawRoundRectFromCss(this, new Rectangle(0, 0, w, h));
		}
	}
} 