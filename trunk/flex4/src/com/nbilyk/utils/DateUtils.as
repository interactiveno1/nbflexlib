/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	public class DateUtils {
		
		/**
		 * Returns 1 if dateB is the next day or after dateA, 0 if they are the same day, and -1 if dateA is a day before or earlier dateB 
		 */
		public static function dateDayCompare(dateA:Date, dateB:Date):Number {
			if (isSameDay(dateA, dateB))
				return 0;
			if (dateA.time < dateB.time) {
				return 1;
			} else {
				return -1;
			}
		}

		public static function isSameDay(dateA:Date, dateB:Date):Boolean {
			if (dateA.getFullYear() == dateB.getFullYear() && dateA.getMonth() == dateB.getMonth() && dateA.getDate() == dateB.getDate()) {
				return true;
			}
			return false;
		}
		public static function dateSwap(dateA:Date, dateB:Date):void {
			var tmp:Number = dateA.time;
			dateA.time = dateB.time;
			dateB.time = tmp;
		}
		
		public static function percentBetween(value:Date, beginDate:Date, endDate:Date):Number {
			return (value.time - beginDate.time) / (endDate.time - beginDate.time);
		}
	}
}