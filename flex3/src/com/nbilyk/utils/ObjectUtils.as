/**
 * Copyright (c) 2008 Nicholas Bilyk
 */
package com.nbilyk.utils {
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	import mx.utils.DescribeTypeCache;
	
	/**
	 * @author nbilyk
	 */
	public class ObjectUtils {
		
		/**
		 * Clones either an object or an array.  The same as Flex's ObjectUtil.clone method.
		 * Use registerClassAlias if you want to retain class type.
		 */
		public static function clone(source:Object):* {
			var copier:ByteArray = new ByteArray();
			copier.writeObject(source);
			copier.position = 0;
			return copier.readObject();
		}
		
		/**
		 * Compares two generic objects and returns true of all recursive properties match.
		 */
		public static function compare(objectA:Object, objectB:Object):Boolean {
			if (objectA == objectB) return true;
			if (objectA == null || objectB == null) return false;
			if (objectA.constructor != objectB.constructor) return false;
			
			var bytesA:ByteArray = new ByteArray();
			bytesA.writeObject(objectA);
			var lengthA:uint = bytesA.length;
			var bytesB:ByteArray = new ByteArray();
			bytesB.writeObject(objectB);
			var lengthB:uint = bytesB.length;
			
			if (lengthA != lengthB) return false;
			
			bytesA.position = 0;
			bytesB.position = 0;
			for (var i:int = 0; i < lengthA; i++) {
				if (bytesA.readByte() != bytesB.readByte()) {
					return false;
				}
			}
			return true;
		}
		
		/**
		 * Takes objectB and merges it into objectA. 
		 */
		public static function mergeObjects(objectA:*, objectB:*, transferNulls:Boolean = false, useCache:Boolean = true):void {
			if (getQualifiedClassName(objectA) != getQualifiedClassName(objectB)) throw new ArgumentError("objectA and objectB are not the same type.");
			var typeXml:XML;
			if (useCache) {
				typeXml = DescribeTypeCache.describeType(objectA).typeDescription;
			} else {
				typeXml = describeType(objectA);
			}
			for each (var variable:XML in typeXml.variable) {
				if (transferNulls || objectB[variable.@name] != null) {
					objectA[variable.@name] = objectB[variable.@name];
				}
			}
			for each (var accessor:XML in typeXml.accessor) {
				if (accessor.@access == "readwrite") {
					if (transferNulls || objectB[accessor.@name] != null) {
						objectA[accessor.@name] = objectB[accessor.@name];
					}
				}
			}
		}
		
		/**
		 * Like compare, except only primitive types matter.  
		 * If objectA has a child object with no values and objectB doesn't have that object, 
		 * they still compare as true because no primitive types had to be evaluated.
		 */
		public static function compareObjectValues(objectA:Object, objectB:Object):Boolean {
			if (!!objectA != !!objectB) return false;
			var comparison:Boolean;
			comparison = recursiveCompare(objectA, [], objectB);
			if (!comparison) return false;
			comparison = recursiveCompare(objectB, [], objectA);
			if (!comparison) return false;
			return true;
		}
		private static function recursiveCompare(nestedObject:Object, nestedNames:Array, objectB:Object, recursionDict:Dictionary = null):Boolean {
			if (!recursionDict) recursionDict = new Dictionary(true);
			if (recursionDict[nestedObject]) return true;
			recursionDict[nestedObject] = true;
			
			for (var all:String in nestedObject) {
				if (!all || nestedObject[all] == null) continue;
				switch (typeof(nestedObject[all])) {
					case ("object") :
						var comparison:Boolean = recursiveCompare(nestedObject[all], nestedNames.concat(all), objectB, recursionDict);
						if (!comparison) return false;
						break;
					case ("boolean") :
					case ("string") :
					case ("number") :
						var obj:Object = objectB;
						for each (var prop:String in nestedNames) {
							obj = obj[prop];
							if (!obj) return false;
						}
						var comparison2:Boolean = nestedObject[all] == obj[all];
						if (!comparison2) return false;
						break;
				}
			}
			return true;
		}
	}
}
