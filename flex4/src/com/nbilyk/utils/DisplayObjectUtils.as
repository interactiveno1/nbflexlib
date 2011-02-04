package com.nbilyk.utils {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	

	public class DisplayObjectUtils {
		
		/**
		 * Takes a target DisplayObject, rasterizes it into a Bitmap, and returns it in a container Sprite 
		 * transformed to be identical to the target.
		 */
		public static function rasterize(target:DisplayObject, useAlpha:Boolean = true, scaleX:Number = 1, scaleY:Number = 1):Sprite {
			var bounds:Rectangle = target.getBounds(target);
			var bmpd:BitmapData = new BitmapData(target.width * scaleX, target.height * scaleY, useAlpha, 0x00000000);
			var mat:Matrix = new Matrix();
			mat.translate(-bounds.left, -bounds.top);
			mat.scale(scaleX, scaleY);
			bmpd.draw(target, mat);

			var bmp:Bitmap = new Bitmap(bmpd, PixelSnapping.ALWAYS, true);
			bmp.x = bounds.left;
			bmp.y = bounds.top;
			var container:Sprite = new Sprite();
			container.cacheAsBitmap = true;
			container.transform.matrix = target.transform.matrix;
			container.addChild(bmp);
			return container;
		}
	}
}