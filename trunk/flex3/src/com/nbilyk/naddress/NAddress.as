package com.nbilyk.naddress {
	import com.nbilyk.naddress.events.NAddressEvent;
	
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;

	[Event(name="fragmentChange", type="com.nbilyk.naddress.events.NAddressEvent")]
	public class NAddress extends EventDispatcher {
		private static var _instance:NAddress;
		
		private var jsIsAvailable:Boolean;
		private var _fragment:String;
		
		public function NAddress(s:SingletonEnforcer) {
			super();
			if (ExternalInterface.available) {
				_fragment = ExternalInterface.call("SWFAddress.getValue");;
				jsIsAvailable = !!_fragment;
				if (jsIsAvailable) ExternalInterface.addCallback("setSWFAddressValue", fragmentChangeHandler);
			}
		}
		
		public static function get instance():NAddress {
			if (!_instance) _instance = new NAddress(new SingletonEnforcer());
			return _instance;
		}
		
		private function fragmentChangeHandler(value:String):void {
			_fragment = value;
			dispatchEvent(new NAddressEvent(NAddressEvent.FRAGMENT_CHANGE, true, _fragment));
		}
		
		//-------------------------
		// Getters / setters
		//-------------------------
		
		[Bindable("fragmentChange")]
		public function get fragment():String {
			return _fragment;
		}
		
		public function set fragment(value:String):void {
			if (_fragment == value) return; // no-op
			if (jsIsAvailable) ExternalInterface.call("SWFAddress.setValue", value);
			_fragment = value;
			dispatchEvent(new NAddressEvent(NAddressEvent.FRAGMENT_CHANGE, false, _fragment));
		}
		
		public function getTitle():String {
			if (jsIsAvailable) ExternalInterface.call("SWFAddress.getTitle");
			return "";
		}
		
		public function setTitle(value:String):void {
			if (jsIsAvailable) ExternalInterface.call("SWFAddress.setTitle", value);
		}
		
		public function getStatus():String {
			if (jsIsAvailable) ExternalInterface.call("SWFAddress.getStatus");
			return "";
		}
		
		public function setStatus(value:String):void {
			if (jsIsAvailable) ExternalInterface.call("SWFAddress.setStatus", value);
		}
		
		public function getPath():String {
			if (jsIsAvailable) ExternalInterface.call("SWFAddress.getPath");
			return "";
		}
	}
}
class SingletonEnforcer {}