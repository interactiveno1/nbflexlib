package com.nbilyk.naddress {
	import com.nbilyk.history.PrettyHistoryManager;
	import com.nbilyk.naddress.events.NAddressEvent;
	
	import flash.events.Event;
	
	public class NAddressPrettyHistory {
		
		private static var _instance:NAddressPrettyHistory;
		
		public function NAddressPrettyHistory(s:SingletonEnforcer) {
		}
		
		/**
		 * Registers NAddress with the PrettyHistoryManager
		 */
		public static function register():void {
			if (_instance) return; 
			_instance = new NAddressPrettyHistory(new SingletonEnforcer());
			_instance.register();
		}
		
		/**
		 * Unegisters NAddress with the PrettyHistoryManager
		 */
		public static function unregister():void {
			if (!_instance) return;
			_instance.unregister();
			_instance = null;
		}
		
		private function register():void {
			NAddress.instance.addEventListener(NAddressEvent.FRAGMENT_CHANGE, urlFragmentChangeHandler);
			PrettyHistoryManager.instance.addEventListener(PrettyHistoryManager.ACTION_CHANGE, prettyHistoryManagerUrlChangedHandler);
			PrettyHistoryManager.instance.fragment = NAddress.instance.fragment;
		}
		
		private function urlFragmentChangeHandler(event:NAddressEvent):void {
			if (event.isExternal) PrettyHistoryManager.instance.fragment = NAddress.instance.fragment;
		}
		
		private function prettyHistoryManagerUrlChangedHandler(event:Event):void {
			NAddress.instance.fragment = PrettyHistoryManager.instance.fragment;
		}
		
		private function unregister():void {
			NAddress.instance.removeEventListener(NAddressEvent.FRAGMENT_CHANGE, urlFragmentChangeHandler);
			PrettyHistoryManager.instance.removeEventListener(PrettyHistoryManager.ACTION_CHANGE, prettyHistoryManagerUrlChangedHandler);
		}

	}
}
class SingletonEnforcer {}