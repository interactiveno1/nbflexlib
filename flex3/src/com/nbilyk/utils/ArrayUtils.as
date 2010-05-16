package com.nbilyk.utils {
	
	/**
	 * A collection of utility function for arrays.
	 */
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
		
		/**
		 * Returns an array containing all the values of arrayA that are present in arrayB. 
		 */
		public static function intersect(arrayA:Array, arrayB:Array):Array {
			var newArray:Array = [];
			for each (var value:* in arrayA) {
				if (arrayB.indexOf(value) != -1) {
					newArray.push(value);
				}
			}
			return newArray;
		}
		
		/**
		 * Compares arrayA against arrayB and returns the difference.
		 */
		public static function diff(arrayA:Array, arrayB:Array):Array {
			var newArray:Array = [];
			for each (var value:* in arrayA) {
				if (arrayB.indexOf(value) == -1) {
					newArray.push(value);
				}
			}
			return newArray;
		}
		
		/**
		 * Takes an input array and returns a new array without duplicate values.
		 */
		public static function unique(array:Array):Array {
			var arrayL:uint = array.length;
			if (!arrayL) return [];
			var newArray:Array = [array[0]];
			for (var i:uint = 1; i < arrayL; i++) {
				var item:* = array[i];
				if (array.lastIndexOf(item, i - 1) == -1) {
					newArray.push(item);
				}
			}
			return newArray;
		}
		
	}
}