package com.nbilyk.utils {
	import flash.display.Graphics;
	import flash.geom.Point;

	public class Bezier {
		
		public static function drawBezier(g:Graphics, points:Array /* Type Point */, precision:Number = 1, isShape:Boolean = true):void {
			if (points.length < 3) return;
			var i:uint;
			var startPoint:Point;
			var endPoint:Point;
			var pointsL:uint;
			var p:Point;
				
			points = points.slice(); // Create a shallow clone of the array.
			startPoint = points.shift();
			endPoint = points.pop();
			g.moveTo(startPoint.x, startPoint.y);
			
			pointsL = points.length;
			
			var xValues:Array = new Array(pointsL); /* Type Number */
			var yValues:Array = new Array(pointsL); /* Type Number */
			
			i = 0;
			for each (p in points) {
				xValues[i] = p.x;
				yValues[i] = p.y;
				i++;
			}
			
			for (i = 0; i < 1000; i++) {
				var xVal:Number = getBezier(i / 1000, startPoint.x, endPoint.x, xValues);
				var yVal:Number = getBezier(i / 1000, startPoint.y, endPoint.y, yValues);
				g.lineTo(xVal, yVal);
			}
		}
		
		/**
		 * Returns the bezier dependent variable based on a set of anchors and beginning/ending values.
		 * Attributed to Robert Penner and the authors of Tweener: Zeh Fernando, Nate Chatellier, and Arthur Debert
		 *
		 * @param b	Beginning value of the property
		 * @param e Ending value of the property
		 * @param t	Current t of this tweening (0-1), after applying the easing equation
		 * @param p	Array of parameters passed to this specific property
		 *
		 * @return New t, with the p parameters applied to it
		 */
		public static function getBezier(t:Number, b:Number, e:Number, anchors:Array):Number {
			var p1:Number;
			var p2:Number;
			var anchorsL:uint = anchors.length;
			if (anchorsL == 1) {
				// Simple curve with just one bezier control point
				return t * (2 * (1 - t) * (anchors[0] - b) + t * (e - b)) + b;
			} else {
				// Array of bezier control points, must find the point between each pair of bezier points
				var iP:uint = uint(t * anchorsL); // Position on the bezier list
				var iT:Number = t * anchorsL - iP; // t inside this ip
				
				if (iP == 0) {
					// First part: belongs to the first control point, find second midpoint
					p1 = b;
					p2 = (anchors[0] + anchors[1]) / 2;
				} else if (iP == anchorsL - 1) {
					// Last part: belongs to the last control point, find first midpoint
					p1 = (anchors[iP - 1] + anchors[iP]) / 2;
					p2 = e;
				} else {
					// Any middle part: find both midpoints
					p1 = (anchors[iP - 1] + anchors[iP]) / 2;
					p2 = (anchors[iP] + anchors[iP + 1]) / 2;
				}
				return iT * (2 * (1 - iT) * (anchors[iP] - p1) + iT * (p2 - p1)) + p1;
			}
		}
	}
}