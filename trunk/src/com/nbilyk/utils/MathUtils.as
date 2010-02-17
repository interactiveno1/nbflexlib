/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {

	public final class MathUtils {
		
		/**
		 * Examples: 										<br />
		 * MathUtils.float(12345.67, -1) returns 12350		<br />
		 * MathUtils.float(12345.67, -2) returns 12300		<br />
		 * MathUtils.float(12345.67, 1) returns 12345.7		<br />
		 */
		public static function float(val:Number, sigDigits:Number):Number {
			var m:Number = Math.pow(10, sigDigits);
			return Math.round(val * m) / m;
		}
		/**
		 * Pads a number with zeros either in the fraction part, or the integer part.
		 * @param val The number to be padded
		 * @param integerDigits The number of digits to pad the integer part. Example: If val is 23 and integerDigits is 4, the return value will be "0023".  
		 * @param fractionDigits The number of digits to pad the fractional part.  Example: If val is 1.23 and fractionDigits is 4, the return value will be "1.2300"  
		 */
		public static function padNumber(val:Number, integerDigits:int, fractionDigits:int = 0):String {
			var valParts:Array = val.toString().split(".");
			var iPart:String = valParts[0];
			var fPart:String = (valParts.length > 1) ? valParts[1] : "";
			var i_str:String = iPart;
			var f_str:String = fPart;
			var missingDigits:int;
			var padNumber:Number;
			
			if (integerDigits > 0) {
				missingDigits = integerDigits - iPart.length;
				if (missingDigits > 0) {
					padNumber = Math.pow(10, missingDigits);
					i_str = padNumber.toString().substr(1) + iPart;
				}
			}
			if (fractionDigits > 0) {
				missingDigits = fractionDigits - fPart.length;
				if (missingDigits > 0) {
					padNumber = Math.pow(10, missingDigits);
					f_str = fPart + padNumber.toString().substr(1);
				}				
			}
			var return_str:String = i_str;
			if (f_str) return_str += "." + f_str;
			return return_str;
		}
		/**
		 * Returns the log (base 2) of [x] (to nearest int).  (32 bit integers.)	<br />
		 * x = 23      (00010111b)													<br />
		 * log2(x) would return 4. 													<br />
		 * About twice as fast as the equivalent: int(Math.log(i)/Math.LN2);		<br />
		 */
		public function log2(x:int):int {
			var num:int = x >> 16;
			var sign:int = int(!num);
			var ans:int = (sign << 4) ^ 24;
			
			num = x >> (ans);
			sign = int(!num);
			ans = (sign << 3) ^ (ans + 4);		
			
			num = x >> (ans);
			sign = int(!num);
			ans = (sign << 2) ^ (ans + 2);
	
			num = x >> (ans);
			sign = int(!num);
			ans = (sign << 1) ^ (ans + 1);		
			
			num = x >> (ans);
			sign = int(!num);
			ans = sign ^ ans;
	
			return ans;
		}
		/**
		 * Returns the lowest bit position.  (32 bit integers.) Basically the opposite of log2	<br />
		 * x = 104      (1101000b)																<br />
		 * lowestbit(x) would return 3.															<br />
		 */ 
		public function lowestbit(x:int):int {
			var num:int = x << 16;
			var sign:int = int(!num);	
			var ans:int = (sign << 4) ^ 24;
			
			num = x << (ans);
			sign = int(!num);
			ans = (sign << 3) ^ (ans + 4);		
			
			num = x << (ans);
			sign = int(!num);
			ans = (sign << 2) ^ (ans + 2);
	
			num = x << (ans);
			sign = int(!num);
			ans = (sign << 1) ^ (ans + 1);		
			
			num = x << (ans);
			sign = int(!num);
			ans = sign ^ ans;
	
			return 31 - ans;
		}
		/**
		 * @param arr the array to calculate the mean of.
		 */
		public static function average(arr:Array):Number {
			return MathUtils.sum(arr) / arr.length;
		}
		/**
		 * @param arr the array to calculate the sum of.
		 */
		public static function sum(arr:Array):Number {
			var sum:Number = 0;
			var len:Number = arr.length;
			for (var i:Number = 0;i < len; i++) {
				sum += arr[i];
			}
			return sum;
		}
		public static function randomRange(m:Number, n:Number):Number {
			var a:Number = Math.max(m, n);
			var b:Number = Math.min(m, n);
			return Math.floor(Math.random() * (a - b)) + b;
		}
		public static function clamp(value:Number, min:Number, max:Number):Number {
			value = Math.max(min, value);
			value = Math.min(max, value);
			return value;
		}
		public static function snap(value:Number, snapInterval:Number, offset:Number):Number {
			value -= offset;
			value /= snapInterval;
			value = Math.round(value);
			value *= snapInterval;
			value += offset;
			return value;
		}
		/**
		 * The function Math.abs in flash is extremely inefficient.  Use this instead.
		 */
		public function abs(x:Number):Number {
			return (x >= 0) ? x : -x;
		}
		
		/**
		 * Returns 1 if x >= 0, 0 if not.
		 */
		public function sign(x:Number):Number {
			return (x >= 0) ? 1 : 0;
		}
		
		/**
		 * Performs the quadratic equation to solve for:
		 * 0 = a ^ 2 + b + c
		 * @return an Array of length 2 where the values are the two possible answers.
		 */
		public function quadratic(a:Number, b:Number, c:Number):Array {
			var d:Number = Math.sqrt(b * b - 4 * a * c);
			return [(-b + d) / (2 * a), (-b - d) / (2 * a)];		}
	}
}