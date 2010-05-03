package com.nbilyk.utils {
	public class ArrayUtils {
		
		/**
		 * @val array The array to be shuffled.
		 * @val maxCount If this is set, the returned array will be limited to this length.
		 * @return A new shuffled array.
		 */
		public static function shuffle(array:Array, maxCount:int = int.MAX_VALUE):Array {
			var oldArray:Array = array.slice();
			var shuffledArray:Array = [];
			var oldArrayL:uint = oldArray.length;
			maxCount = Math.min(maxCount, oldArrayL);
			while (maxCount--) {
			    shuffledArray.push(oldArray.splice(Math.floor(Math.random() * oldArrayL), 1)[0]);
			    oldArrayL--;
			}
			return shuffledArray;
		}
	}
}