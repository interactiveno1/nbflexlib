/**
 * @author Nicholas Bilyk - April 2009
 */
package com.nbilyk.utils {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.getTimer;
	
	import spark.components.RichEditableText;
	import spark.core.IViewport;

	/**
	 * To use via mxml:
	 * <nbilyk:KineticScrollManager target="{targetViewPort}"/>
	 *
	 * To use via actionscript:
	 * create a non-temporary instance of KineticScrollManager, passing the UIComponent you wish to
	 * use kinetic scrolling on.
	 *
	 * Example:
	 * private var ksm:KineticScrollManager;
	 * ksm = new KineticScrollManager(component);
	 */
	public class KineticScrollManager {
		private static const HISTORY_LENGTH:uint = 5; // The amount of mouse move events to keep track of

		private var _target:IViewport;
		[ArrayElementType("Point")]
		private var previousPoints:Array;
		[ArrayElementType("int")]
		private var previousTimes:Array;
		private var velocity:Point = new Point();
		private var _enabled:Boolean = true;
		
		/**
		 * Dampening affects how quickly the toss velocity will slow to a stop.
		 * Make this number 0 < dampening < 1.  Where 1 will go forever, and 0 will prevent any momentum.
		 */
		public var dampening:Number = .8;
		
		public var horizontalScrollEnabled:Boolean = true;
		public var verticalScrollEnabled:Boolean = true;
		
		public function KineticScrollManager(targetVal:IViewport = null) {
			target = targetVal;
		}

		public function get targetDisplayObject():DisplayObject {
			return _target as DisplayObject;
		}
		
		public function get target():IViewport {
			return _target;
		}

		public function set target(value:IViewport):void {
			if (_target) removeAllListeners();
			_target = value;
			if (value) {
				target.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
				target.addEventListener(MouseEvent.CLICK, mouseClickHandler, true, 100, true);
			}
		}

		private function mouseDownHandler(event:MouseEvent):void {
			if (!enabled) return;
			if (event.target is TextField && TextField(event.target).selectable) return;
			if (event.target is RichEditableText && (RichEditableText(event.target).editable || RichEditableText(event.target).selectable)) return;
			
			if (hasMouseEventListeners(targetDisplayObject)) return;
			
			stop();
			previousPoints = [new Point(targetDisplayObject.stage.mouseX, targetDisplayObject.stage.mouseY)];
			previousTimes = [getTimer()];
			targetDisplayObject.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false, 0, true);
			targetDisplayObject.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
		}
		
		private function hasMouseEventListeners(displayTarget:DisplayObject):Boolean {
			if (displayTarget == target) return false;
			if (displayTarget.hasEventListener(MouseEvent.MOUSE_DOWN) || displayTarget.hasEventListener(MouseEvent.MOUSE_UP)) return true;
			if (displayTarget.parent) return hasMouseEventListeners(displayTarget.parent);
			return false;
		}

		private function mouseMoveHandler(event:MouseEvent):void {
			if (!enabled) return;
			if (!event.buttonDown) {
				mouseUpHandler();
				return;
			}
			var currPoint:Point = new Point(targetDisplayObject.stage.mouseX, targetDisplayObject.stage.mouseY);
			var currTime:int = getTimer();
			var previousPoint:Point = Point(previousPoints[previousPoints.length - 1]);
			var diff:Point = currPoint.subtract(previousPoint);
			diff = transformPointToLocal(diff);
			moveScrollPosition(diff);

			// Keep track of a set amount of positions and times so that on release, we can always look back a consistant amount.
			previousPoints.push(currPoint);
			previousTimes.push(currTime);
			if (previousPoints.length >= HISTORY_LENGTH) {
				previousPoints.shift();
				previousTimes.shift();
			}
		}

		private function mouseUpHandler(event:MouseEvent = null):void {
			targetDisplayObject.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			targetDisplayObject.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			if (!enabled) return;
			target.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);

			var currPoint:Point = new Point(targetDisplayObject.stage.mouseX, targetDisplayObject.stage.mouseY);
			var currTime:int = getTimer();
			var firstPoint:Point = Point(previousPoints[0]);
			var firstTime:int = int(previousTimes[0]);
			var diff:Point = currPoint.subtract(firstPoint);
			var time:Number = (currTime - firstTime) / (1000 / targetDisplayObject.stage.frameRate);
			velocity = new Point(diff.x / time, diff.y / time);
		}

		private function enterFrameHandler(event:Event):void {
			velocity = new Point(velocity.x * dampening, velocity.y * dampening);
			var cM:Matrix = targetDisplayObject.transform.concatenatedMatrix;
			var localVelocity:Point = transformPointToLocal(velocity);
			if (Math.abs(localVelocity.x) < .1) localVelocity.x = 0;
			if (Math.abs(localVelocity.y) < .1) localVelocity.y = 0;
			if (!localVelocity.x && !localVelocity.y) stop();
			moveScrollPosition(localVelocity);
		}
		
		private function mouseClickHandler(event:MouseEvent):void {
			if (velocity.length > 5) {
				event.stopImmediatePropagation();
			}
		}

		public function stop():void {
			target.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			velocity = new Point();
		}

		public function setVelocity(value:Point):void {
			if (!value) value = new Point();
			if (!targetDisplayObject.stage) return;
			targetDisplayObject.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			targetDisplayObject.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			targetDisplayObject.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);

			velocity = value;
		}

		private function removeAllListeners():void {
			target.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			target.removeEventListener(MouseEvent.CLICK, mouseClickHandler, true);
			target.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (targetDisplayObject.stage) {
				targetDisplayObject.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				targetDisplayObject.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			}
		}

		public function get enabled():Boolean {
			return _enabled;
		}

		public function set enabled(value:Boolean):void {
			if (value == _enabled)
				return; // no-op
			_enabled = value;
			if (!value) {
				stop();
			}
		}
		
		/**
		 * Moves scroller which moves viewport into position
		 * */
		protected function moveScrollPosition(diff:Point):void {
			if (horizontalScrollEnabled) {
				target.horizontalScrollPosition -= diff.x;
			}
			if (verticalScrollEnabled) {
				target.verticalScrollPosition -= diff.y;
			}
		}
		
		private function transformPointToLocal(p:Point):Point {
			var cM:Matrix = targetDisplayObject.transform.concatenatedMatrix.clone();
			cM.tx = 0;
			cM.ty = 0;
			cM.invert();
			return cM.transformPoint(p);
		}
	}
}