/**
 * @author Nicholas Bilyk - April 2009
 */
package com.nbilyk.utils {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import mx.core.Container;
	
	/**
	 * To use via mxml:
	 * <utils:KineticScrollManager target="{targetContainer}"/>
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
		
		private var _target:Container;
		[ArrayElementType("Point")]
		private var previousPoints:Array;
		[ArrayElementType("int")]
		private var previousTimes:Array;
		private var velocity:Point;
		private var _enabled:Boolean = true;
		
		public function KineticScrollManager(targetVal:Container = null) {
			target = targetVal;
		}
		public function get target():Container {
			return _target;
		}
		public function set target(value:Container):void {
			if (_target) removeAllListeners();
			_target = value;
			if (value) {
				target.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
				target.addEventListener(MouseEvent.CLICK, mouseClickHandler, true, 100, true);
			}
		}
		private function mouseDownHandler(event:MouseEvent):void {
			if (!enabled) return;
			if (target.verticalScrollBar && target.verticalScrollBar.owns(DisplayObject(event.target))) return;
			if (target.horizontalScrollBar && target.horizontalScrollBar.owns(DisplayObject(event.target))) return;
			stop();
			previousPoints = [new Point(target.mouseX, target.mouseY)];
			previousTimes = [getTimer()];
			target.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false, 0, true);
			target.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
		}
		private function mouseMoveHandler(event:MouseEvent):void {
			if (!enabled) return;
			if (!event.buttonDown) {
				mouseUpHandler();
				return;
			}
			var currPoint:Point = new Point(target.mouseX, target.mouseY);
			var currTime:int = getTimer();
			var previousPoint:Point = Point(previousPoints[previousPoints.length - 1]);
			var diff:Point = currPoint.subtract(previousPoint);
			target.horizontalScrollPosition -= diff.x;
			target.verticalScrollPosition -= diff.y;
			
			// Keep track of a set amount of positions and times so that on release, we can always look back a consistant amount.
			previousPoints.push(currPoint);
			previousTimes.push(currTime);
			if (previousPoints.length >= HISTORY_LENGTH) {
				previousPoints.shift();
				previousTimes.shift();
			}
		}
		private function mouseUpHandler(event:MouseEvent = null):void {
			target.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			if (!enabled) return;
			target.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			
			var currPoint:Point = new Point(target.mouseX, target.mouseY);
			var currTime:int = getTimer();
			var firstPoint:Point = Point(previousPoints[0]);
			var firstTime:int = int(previousTimes[0]);
			var diff:Point = currPoint.subtract(firstPoint);
			var time:Number = (currTime - firstTime) / (1000 / 24);
			velocity = new Point(diff.x / time, diff.y / time);
		}
		private function enterFrameHandler(event:Event):void {
			velocity = new Point(velocity.x * .8, velocity.y * .8);
			if (Math.abs(velocity.x) < .1) velocity.x = 0;
			if (Math.abs(velocity.y) < .1) velocity.y = 0;
			if (!velocity.x && !velocity.y) stop();
			target.horizontalScrollPosition -= velocity.x;
			target.verticalScrollPosition -= velocity.y;
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
			if (!target.stage) return;
			target.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			target.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			
			velocity = value;
		}
		private function removeAllListeners():void {
			target.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			target.removeEventListener(MouseEvent.CLICK, mouseClickHandler, true);
			target.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (target.stage) {
				target.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			}
		}
		
		public function get enabled():Boolean {
			return _enabled;
		}
		public function set enabled(value:Boolean):void {
			if (value == _enabled) return; // no-op
			_enabled = value;
			if (!value) {
				stop();
			}
		}
	}
}