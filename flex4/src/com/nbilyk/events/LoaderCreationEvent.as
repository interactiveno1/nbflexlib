/**
 * Copyright (c) 2008 Nicholas Bilyk
 */

package com.nbilyk.events {
	import flash.display.Loader;	
	import flash.events.Event;
	
	public class LoaderCreationEvent extends Event {
		public static const LOADER_CREATION_COMPLETE:String = "loaderCreationComplete";
		public static const LOADER_CREATION_ERROR:String = "loaderCreationError";
		
		public var loader:Loader;

		public function LoaderCreationEvent(loaderVal:Loader, type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
			loader = loaderVal;
		}
	}
}
