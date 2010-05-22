package com.nbilyk.managers {

	public interface IPrettyHistoryManagerClient {
		
		/**
		 * Most often this is 1, but if you have more parameters you can increase this.
		 * This determines the number of arguments expected from loadState and how many to give saveState.
		 */
		function getParamCount():uint;
		
		/**
		 * The index of the url fragment to this client is concerned with.  This is coupled with getParamCount to 
		 * determine which slice of the fragment to give the client.
		 */
		function getClientDepth():uint;
		
		/**
		 * @param args An array of length getParamCount(). 
		 */
		function loadState(args:Array):void;
		
		/**
		 * @return An array of length getParamCount(). 
		 */
		function saveState():Array;
		
		/**
		 * @return An array with the default state of the client. 
		 * This array should be of length getParamCount().
		 * Return null if the default state cannot yet be determined. 
		 * Once the client is ready, call PrettyHistoryManager.load. 
		 */
		function getDefaultState():Array;
	}
}