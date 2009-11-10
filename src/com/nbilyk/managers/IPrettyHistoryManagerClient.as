package com.nbilyk.managers {

	public interface IPrettyHistoryManagerClient {
		function getClientDepth():uint;
		function loadState(value:String):void;
		function saveState():String;
	}
}