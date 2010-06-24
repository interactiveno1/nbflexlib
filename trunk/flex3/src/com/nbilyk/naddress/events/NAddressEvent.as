package com.nbilyk.naddress.events {
	import flash.events.Event;

	public class NAddressEvent extends Event {
		public static const FRAGMENT_CHANGE:String = "fragmentChange";
		
		public var isExternal:Boolean;
		public var fragment:String;
		
		public function NAddressEvent(type:String, isExternal:Boolean, fragment:String) {
			super(type, false, false);
			this.isExternal = isExternal;
			this.fragment = fragment;
		}

	}
}