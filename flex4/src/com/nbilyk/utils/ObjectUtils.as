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
		
		public static const PRIMITIVE_TYPES:Vector.<String> = new <String>["String", "Number", "uint", "int", "Boolean", "Date", "Array"];
		public static const IGNORE_TYPES:Vector.<String> = new <String>["*", "Function"];
		
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
		 * Takes objectB and recursively imposes its property values into objectA. 
		 * 
		 * @param objectA The object whose properties will be replaced.
		 * @param objectB The object to take the properties of to place on objectA
		 * @param transferNulls If true, null values from objectB will transfer to objectA
		 * @param useCache If true, the type descriptor will be retrieved from DescribeTypeCache and not describeType
		 */
		public static function mergeObjects(objectA:*, objectB:*, transferNulls:Boolean = false, useCache:Boolean = true, recursive:Boolean = true, ignoreTransient:Boolean = false):void {
			if (getQualifiedClassName(objectA) != getQualifiedClassName(objectB)) throw new ArgumentError("objectA and objectB are not the same type.");
			internalMergeObjects(objectA, objectB, transferNulls, useCache, recursive, ignoreTransient, new Dictionary(true));
		}
		
		private static function internalMergeObjects(objectA:*, objectB:*, transferNulls:Boolean, useCache:Boolean, recursive:Boolean, ignoreTransient:Boolean, ref:Dictionary):void {
			if (getQualifiedClassName(objectA) != getQualifiedClassName(objectB)) return; // Do not try to merge objects of different types.
			ref[objectA] = true;
			var typeXml:XML;
			if (useCache) {
				typeXml = DescribeTypeCache.describeType(objectA).typeDescription;
			} else {
				typeXml = describeType(objectA);
			}
			var properties:XMLList = typeXml.children().((name() == "accessor" && @access == "readwrite") || name() == "variable");
			for each (var property:XML in properties) {
				if (ignoreTransient && property.metadata.(@name == "Transient").length() > 0) continue;
				var propertyValueA:* = objectA[property.@name];
				var propertyValueB:* = objectB[property.@name];
				if (transferNulls || propertyValueB != null) {
					var propertyType:String = property.@type;
					if (IGNORE_TYPES.indexOf(propertyType) != -1) {
						// Ignore
					} else if (PRIMITIVE_TYPES.indexOf(propertyType) == -1 && recursive) {
						// Not a primitive type, recurse into the sub-object.
						if (propertyValueA != null && propertyValueB != null) {
							if (!ref[propertyValueA]) {
								internalMergeObjects(propertyValueA, propertyValueB, transferNulls, useCache, recursive, ignoreTransient, ref);
							}
						} else {
							objectA[property.@name] = propertyValueB;
						}
					} else {
						// A primitive type
						objectA[property.@name] = propertyValueB;
					}
				}
			}
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
					case "object" :
						var comparison:Boolean = recursiveCompare(nestedObject[all], nestedNames.concat(all), objectB, recursionDict);
						if (!comparison) return false;
						break;
					case "boolean" :
					case "string" :
					case "number" :
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
