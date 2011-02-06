package com.nbilyk.events {
	import flash.events.Event;
	import flash.geom.Point;

	public class KineticScrollManagerEvent extends Event {
		
		public static const TOSS_START:String = "tossStart";
		public static const TOSS_END:String = "tossEnd";
		
		/**
		 * The Point indicating the velocity of the kinetic scroll manager at the event.
		 */
		public var velocity:Point;
		
		public function KineticScrollManagerEvent(type:String, velocity:Point, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
			this.velocity = velocity;
		}
		
		override public function clone():Event {
			return new KineticScrollManagerEvent(type, velocity, bubbles, cancelable);
		}
	}
}