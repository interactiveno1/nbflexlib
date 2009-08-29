/**
 * Copyright (c) 2006, 2007 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class CoordMath {
		public static function convertCoords(point:Point, fromClip:DisplayObject, toClip:DisplayObject):Point {
			if (toClip == null || fromClip == null) return point.clone();
			point = fromClip.localToGlobal(point);
			point = toClip.globalToLocal(point);
			return point;
		}
		public static function convertDistance(distance:Point, fromClip:DisplayObject, toClip:DisplayObject):Point {
			if (toClip == null || fromClip == null) return distance.clone();
			var topLeft:Point = new Point(0, 0);
			topLeft = CoordMath.convertCoords(topLeft, fromClip, toClip);
			distance = CoordMath.convertCoords(distance, fromClip, toClip);
			distance.x -= topLeft.x;
			distance.y -= topLeft.y;	
			return distance;
		}
		
		/**
		 * Sometimes you can't use the getBounds(target) method because of things like masks.
		 */
		public static function convertBounds(bounds:Rectangle, fromClip:DisplayObject, toClip:DisplayObject):Rectangle {
			var p1:Point = convertCoords(bounds.topLeft, fromClip, toClip);
			var p2:Point = convertCoords(new Point(bounds.bottomRight.x, bounds.topLeft.y), fromClip, toClip);
			var p3:Point = convertCoords(bounds.bottomRight, fromClip, toClip);
			var p4:Point = convertCoords(new Point(bounds.topLeft.x, bounds.bottomRight.y), fromClip, toClip);
			
			var x1:Number = Math.min(p1.x, p2.x, p3.x, p4.x);
			var y1:Number = Math.min(p1.y, p2.y, p3.y, p4.y);
			var x2:Number = Math.max(p1.x, p2.x, p3.x, p4.x);
			var y2:Number = Math.max(p1.y, p2.y, p3.y, p4.y);
			var r:Rectangle = new Rectangle();
			r.topLeft = new Point(x1, y1);
			r.bottomRight = new Point(x2, y2);
			return r;
		}
	}
}