/**
 * Copyright (c) 2007 Nicholas Bilyk
 */
package com.nbilyk.display {
	public interface IPreloader {
		function updateProgress(bytesLoaded:Number, bytesTotal:Number):void;
		function hide():void;
		function show():void;
	}
}