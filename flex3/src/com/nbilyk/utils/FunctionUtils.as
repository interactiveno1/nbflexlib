/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	public class FunctionUtils {
		private static var funcTimerDict:Dictionary = new Dictionary(true);

		public static function delayedCall(func:Function, time:Number = 10, args:Array = null):void {
			var existingTimer:Timer = Timer(funcTimerDict[func]);
			if (existingTimer) {
				existingTimer.stop();
				existingTimer.delay = time;
				existingTimer.start();
			} else {
				var timer:Timer = new Timer(time, 1);
				funcTimerDict[func] = timer;

				var dfc:DeferredFunctionCall = new DeferredFunctionCall(func, args);
				dfc.addEventListener(DeferredFunctionCall.CALLED, functionCalledHandler, false, 0, true);
				timer.addEventListener(TimerEvent.TIMER, dfc.call);
				timer.start();
			}
		}

		public static function delayedCallFrames(func:Function, frames:int = 1, args:Array = null):void {
			var existingTimer:TimerClip = TimerClip(funcTimerDict[func]);
			if (existingTimer) {
				existingTimer.frameCount = frames;
			} else {
				var timerClip:TimerClip = new TimerClip(frames);
				funcTimerDict[func] = timerClip;

				var dfc:DeferredFunctionCall = new DeferredFunctionCall(func, args);
				dfc.addEventListener(DeferredFunctionCall.CALLED, functionCalledHandler, false, 0, true);
				timerClip.addEventListener(Event.COMPLETE, dfc.call);
			}
		}

		private static function functionCalledHandler(event:Event):void {
			var dfc:DeferredFunctionCall = DeferredFunctionCall(event.currentTarget);
			delete funcTimerDict[dfc.func];
		}

		public static function limit(func:Function, time:Number = 10, args:Array = null):Boolean {
			var existingTimer:Timer = Timer(funcTimerDict[func]);
			if (existingTimer) {
				if (existingTimer.currentCount) {
					delete funcTimerDict[func];
					return true;
				}
			} else {
				var timer:Timer = new Timer(time, 1);
				funcTimerDict[func] = timer;

				var dfc:DeferredFunctionCall = new DeferredFunctionCall(func, args);
				timer.addEventListener(TimerEvent.TIMER, dfc.call);
				timer.start();
			}
			return false;
		}

		public static function limitFrames(func:Function, frames:int = 1, args:Array = null):Boolean {
			var existingTimer:TimerClip = TimerClip(funcTimerDict[func]);
			if (existingTimer) {
				if (existingTimer.hasCompleted) {
					delete funcTimerDict[func];
					return true;
				}
			} else {
				var timerClip:TimerClip = new TimerClip(frames);
				funcTimerDict[func] = timerClip;

				var dfc:DeferredFunctionCall = new DeferredFunctionCall(func, args);
				timerClip.addEventListener(Event.COMPLETE, dfc.call);
			}
			return false;
		}

		public static function callOnEvent(eventDispatcher:IEventDispatcher, eventName:String, func:Function, args:Array = null, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			var dfc:DeferredFunctionCall = new DeferredFunctionCall(removeCallOnEventListener, [ eventDispatcher, eventName, func, args ]);
			dfc.args.unshift(dfc);
			eventDispatcher.addEventListener(eventName, dfc.call, useCapture, priority, useWeakReference);
		}

		private static function removeCallOnEventListener(dfc:DeferredFunctionCall, eventDispatcher:IEventDispatcher, eventName:String, func:Function, args:Array = null):void {
			eventDispatcher.removeEventListener(eventName, dfc.call);
			func.apply(null, args);
		}

		public static function interrupt(func:Function):Boolean {
			var t:* = funcTimerDict[func];
			if (t) {
				if (t is Timer) {
					Timer(t).stop();
				} else if (t is TimerClip) {
					TimerClip(t).cancel();
				}
				delete funcTimerDict[func];
				return true;
			} else {
				return false;
			}
		}
	}
}
import flash.display.Sprite;
import flash.events.Event;

[Event(name="complete",type="flash.events.Event")]
class TimerClip extends Sprite {
	public var frameCount:int;
	private var _hasCompleted:Boolean = false;

	public function TimerClip(frameCountVal:int):void {
		super();
		frameCount = frameCountVal;
		addEventListener(Event.ENTER_FRAME, enterFrameHandler);
	}

	private function enterFrameHandler(event:Event):void {
		if (--frameCount <= 0) {
			_hasCompleted = true;
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}

	public function get hasCompleted():Boolean {
		return _hasCompleted;
	}

	public function cancel():void {
		removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
	}
}