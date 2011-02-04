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

		private var _target:DisplayObject;
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
		
		public function KineticScrollManager(targetVal:DisplayObject = null) {
			target = targetVal;
		}

		/**
		 * The target DisplayObject for which to apply the kinetic scrolling.
		 * Must have the properties horizontalScrollPosition and verticalScrollPosition
		 */
		public function get target():DisplayObject {
			return _target;
		}

		public function set target(value:DisplayObject):void {
			if (_target) removeAllListeners();
			_target = value;
			if (value) {
				target.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
				target.addEventListener(MouseEvent.CLICK, mouseClickHandler, true, 100, true);
			}
		}

		protected function mouseDownHandler(event:MouseEvent):void {
			if (!enabled) return;
			if (event.target is TextField && TextField(event.target).selectable) return;
			if (event.target is RichEditableText && (RichEditableText(event.target).editable || RichEditableText(event.target).selectable)) return; // Contrib: Judah Frangipane
			if (hasMouseEventListeners(DisplayObject(event.target))) return;
			
			stop();
			previousPoints = [new Point(target.stage.mouseX, target.stage.mouseY)];
			previousTimes = [getTimer()];
			target.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false, 0, true);
			target.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
		}
		
		private function hasMouseEventListeners(displayTarget:DisplayObject):Boolean {
			if (displayTarget == target) return false;
			if (displayTarget.hasEventListener(MouseEvent.MOUSE_DOWN) || displayTarget.hasEventListener(MouseEvent.MOUSE_UP)) return true;
			if (displayTarget.parent) return hasMouseEventListeners(displayTarget.parent);
			return false;
		}

		protected function mouseMoveHandler(event:MouseEvent):void {
			if (!enabled) return;
			if (!event.buttonDown) {
				mouseUpHandler();
				return;
			}
			var currPoint:Point = new Point(target.stage.mouseX, target.stage.mouseY);
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

		protected function mouseUpHandler(event:MouseEvent = null):void {
			target.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			if (!enabled) return;

			var currPoint:Point = new Point(target.stage.mouseX, target.stage.mouseY);
			var currTime:int = getTimer();
			var firstPoint:Point = Point(previousPoints[0]);
			var firstTime:int = int(previousTimes[0]);
			var diff:Point = currPoint.subtract(firstPoint);
			var time:Number = (currTime - firstTime) / (1000 / target.stage.frameRate);
			velocity = new Point(diff.x / time, diff.y / time);
			start();
		}

		protected function enterFrameHandler(event:Event):void {
			velocity = new Point(velocity.x * dampening, velocity.y * dampening);
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
		
		/**
		 * Starts the enter frame handler
		 */
		protected function start():void {
			target.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}

		/**
		 * Starts the enter frame handler
		 */
		public function stop():void {
			target.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			velocity = new Point();
		}

		/**
		 * Sets the velocity of the scrolling.
		 */
		public function setVelocity(value:Point):void {
			if (!value) value = new Point();
			if (!target.stage) return;
			target.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			
			velocity = value;
			start();
		}

		/**
		 * Removes all listeners from the target and stage.
		 */
		protected function removeAllListeners():void {
			target.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			target.removeEventListener(MouseEvent.CLICK, mouseClickHandler, true);
			target.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (target.stage) {
				target.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			}
		}

		/**
		 * If enabled is false, scrolling will stop and be disabled.
		 */
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
				Object(target).horizontalScrollPosition -= diff.x;
			}
			if (verticalScrollEnabled) {
				Object(target).verticalScrollPosition -= diff.y;
			}
		}
		
		private function transformPointToLocal(p:Point):Point {
			var cM:Matrix = target.transform.concatenatedMatrix.clone();
			cM.tx = 0;
			cM.ty = 0;
			cM.invert();
			return cM.transformPoint(p);
		}
	}
}