package com.nbilyk.xml {
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.formatters.DateFormatter;
	import mx.utils.DescribeTypeCache;

	public final class XMLUtils {

		public static const PRIMITIVE_TYPES:Vector.<String> = new <String>["String", "Number", "uint", "int", "Boolean", "Date"];
		public static const IGNORE_TYPES:Vector.<String> = new <String>["*", "Function"];
		
		private static const VECTOR:String = "__AS3__.vec::Vector";

		private static var dateFormatter:DateFormatter = new DateFormatter();
		
		private static var manifestGroups:Array = []; // Type ManifestGroup
		
		/**
		 * If it exists, returns the ManifestGroup with the namespace that has the given uri.
		 */
		private static function getManifestGroupByUri(uri:String):ManifestGroup {
			for each (var manifestGroup:ManifestGroup in manifestGroups) {
				if (manifestGroup.namespace.uri == uri) {
					return manifestGroup;
				}
			}
			return null;
		}
		
		/**
		 * Finds the ManifestEntry with the given className.
		 * className must be a fully qualified class name.
		 */
		private static function getManifestEntryByClassName(className:String):ManifestEntry {
			for each (var manifestGroup:ManifestGroup in manifestGroups) {
				var manifestEntry:ManifestEntry = manifestGroup.getEntryByClassName(className);
				if (manifestEntry) return manifestEntry;
			}
			return null;
		}
		
		/**
		 * Lists a component with the given alias and class name to the given namespace.
		 * 
		 * e.g.:
		 * XMLUtils.mapNamespace("ArrayCollection", "mx.collections::ArrayCollection", new Namespace("s", "library://ns.adobe.com/flex/spark"));
		 */
		public static function addManifestEntry(alias:String, className:String, namespace:Namespace):void {
			var manifestGroup:ManifestGroup = getManifestGroupByUri(namespace.uri);
			if (!manifestGroup) {
				manifestGroup = new ManifestGroup(namespace);
				manifestGroups.push(manifestGroup);
			}
			
			var manifestEntry:ManifestEntry = new ManifestEntry(alias, className);
			manifestGroup.addEntry(manifestEntry);
		}
		
		/**
		 * Parses a manifest xml file and maps all of its classes to the given namespace.
		 */
		public static function parseManifest(manifest:XML, namespace:Namespace):void {
			for each (var componentXml:XML in manifest.component) {
				var className:String = String(componentXml.attribute("class"));
				var lastDotIndex:int = className.lastIndexOf(".");
				if (lastDotIndex != -1) {
					// Convert com.foo.Bar to com.foo::Bar
					className = className.substr(0, lastDotIndex) + "::" + className.substr(lastDotIndex + 1);
				}
				addManifestEntry(String(componentXml.@id), className, namespace);
			}
		}

		/**
		 * The DateFormatter used in marshalling.
		 */
		public static function getDateFormatter():DateFormatter {
			return dateFormatter;
		}

		/**
		 * Takes XML and deserializes it into an AMF Object.
		 * 
		 * @param xml The xml to convert to an Object
		 * @param useCache Whether or not to use DescribeTypeCache.
		 */
		public static function unmarshall(xml:XML, useCache:Boolean = true):* {
			return internalUnmarshall(xml, useCache);
		}

		private static function internalUnmarshall(xml:XML, useCache:Boolean):* {
			var ns:Namespace = xml.namespace();
			if (!ns) return null;
			
			var className:String;
			var name:String = xml.name();
			var alias:String = name.substring(name.indexOf("::") + 2);
			var manifestGroup:ManifestGroup = getManifestGroupByUri(ns.uri);
			if (manifestGroup) {
				var manifestEntry:ManifestEntry = manifestGroup.getEntryByAlias(alias);
				if (manifestEntry) {
					className = manifestEntry.className;
				}
			}
			if (!className) {
				className = name.replace("\.*", "");
				className = className.replace("*", "");
			}
			if (IGNORE_TYPES.indexOf(className) != -1) return null;
			else if (PRIMITIVE_TYPES.indexOf(className) != -1) return stringToVariable(xml.text(), className);
			
			var isVector:Boolean = className.indexOf(VECTOR) === 0;
			if (isVector) {
				if (xml.hasOwnProperty("@type")) {
					className += ".<" + String(xml.@type) + ">";
				}
			}
			
			var clazz:Class = getDefinitionByName(className) as Class;
			
			var object:Object = new clazz() as Object;
			var typeXml:XML;
			if (useCache) {
				typeXml = DescribeTypeCache.describeType(object).typeDescription;
			} else {
				typeXml = describeType(object);
			}
			var properties:XMLList = typeXml.children().((name() == "accessor" && @access == "readwrite") || name() == "variable");
			
			var childXml:XML;
			if (object is IList) {
				for each (childXml in xml.children()) {
					IList(object).addItem(internalUnmarshall(childXml, useCache));
				}
			} else if (object is Array || isVector) {
				var i:uint = 0;
				for each (childXml in xml.children()) {
					object[i] = internalUnmarshall(childXml, useCache);
					i++;
				}
			} else {
				for each (childXml in xml.children()) {
					var childName:String = childXml.name();
					var propertyName:String = childName.substring(childName.lastIndexOf("::") + 2);
					var propertyList:XMLList = properties.(@name == propertyName);
					if (propertyList.length() == 0) continue;
					var property:XML = propertyList[0];
					
					if (childXml.hasSimpleContent()) {
						object[propertyName] = stringToVariable(String(childXml.text()), String(property.@type));
					} else {
						object[propertyName] = internalUnmarshall(childXml.children()[0], useCache);
					}
				}
			}
			return object;
		}
		
		/**
		 * Takes an Object and serializes it to XML.
		 * 
		 * @param object The object to convert to XML
		 * @param useCache Whether or not to use DescribeTypeCache.
		 * @param ignoreTransient If true, properties with the metadata [Transient] will not be marshalled.
		 */
		public static function marshall(object:*, useCache:Boolean = true, ignoreTransient:Boolean = false):XML {
			return internalMarshall(object, useCache, ignoreTransient, new Dictionary(true), null);
		}

		private static function internalMarshall(object:*, useCache:Boolean, ignoreTransient:Boolean, ref:Dictionary, root:XML):XML {
			var xml:XML = <_/>;
			var qualifiedClassName:String = getQualifiedClassName(object);
			var isVector:Boolean = qualifiedClassName.indexOf(VECTOR) === 0;;
			
			if (isVector) {
				/**
				 * Vectors need special handling, a Vector will have a qualified class name like this:
				 * __AS3__.vec::Vector.<com.example::Foo>
				 * The xml we want to product will be: <fx:Vector type="com.example.Foo"/>
				 */
				if (qualifiedClassName.length > VECTOR.length + 2) {
					var vectorType:String = qualifiedClassName.substring(VECTOR.length + 2, qualifiedClassName.length - 1);
					vectorType = vectorType.replace("::", ".");
					xml.@type = vectorType;
				}
				qualifiedClassName = VECTOR;
			}
			
			var classAlias:String;
			var ns:Namespace;
			var manifestEntry:ManifestEntry = getManifestEntryByClassName(qualifiedClassName);
			if (manifestEntry) {
				ns = manifestEntry.parent.namespace;
				classAlias = manifestEntry.alias;
			} else {
				var splitIndex:int = qualifiedClassName.indexOf("::");
				
				var prefix:String;
				var uri:String;
				if (splitIndex == -1) {
					// No package.
					prefix = "local";
					uri = "*";
					classAlias = qualifiedClassName;
				} else {
					classAlias = qualifiedClassName.substring(splitIndex + 2);
					var packageName:String = qualifiedClassName.substring(0, splitIndex);
					var last:int = packageName.lastIndexOf(".");
					prefix = packageName.substring(last + 1);
					uri = packageName + ".*";
				}
				
				ns = new Namespace(prefix, uri);
			}
			try {
				xml.setName(classAlias);
			} catch (e:Error) {
				trace("Error marshalling object: " + e.toString());
				return xml;
			}
			
			if (root === null) root = xml;
			root.addNamespace(ns);
			xml.setNamespace(ns);
			
			// Check if it's an ignore type, primitive type, or complex type.
			if (IGNORE_TYPES.indexOf(qualifiedClassName) != -1) {
				return xml;
			} else if (PRIMITIVE_TYPES.indexOf(qualifiedClassName) != -1 ) {
				// A primitive type.
				xml.appendChild(variableToString(object, qualifiedClassName));
				return xml;
			}
			
			// Object's type is not ignored and is not primitive. Inspect it and recurse through its child properties.
			if (ref[object]) return xml; // Already marshalled this object; must be a circular reference.
			ref[object] = true;
			
			var item:*;
			var childXml:XML;
			var list:IList = object as IList;
			if (list) {
				var n:uint = list.length;
				for (var i:uint = 0; i < n; i++) {
					item = list.getItemAt(i);
					childXml = internalMarshall(item, useCache, ignoreTransient, ref, root);
					xml.appendChild(childXml);
				}
			} else if (object is Array || isVector) {
				for each (item in object) {
					childXml = internalMarshall(item, useCache, ignoreTransient, ref, root);
					xml.appendChild(childXml);
				}
			} else {
				var typeXml:XML;
				if (useCache) {
					typeXml = DescribeTypeCache.describeType(object).typeDescription;
				} else {
					typeXml = describeType(object);
				}
				var properties:XMLList = typeXml.children().((name() == "accessor" && @access == "readwrite") || name() == "variable");
				for each (var property:XML in properties) {
					if (ignoreTransient && property.metadata.(@name == "Transient").length() > 0) continue;
					var propName:String = property.@name;
					item = object[propName];
					childXml = internalMarshall(item, useCache, ignoreTransient, ref, root);
					
					var complexChildXml:XML = <{propName}/>;
					if (ns) complexChildXml.setNamespace(ns);
					if (childXml.hasComplexContent()) {
						complexChildXml.appendChild(childXml);
					} else {
						complexChildXml.appendChild(childXml.text());
					}
					xml.appendChild(complexChildXml)
				}
			}
			return xml;
		}
		
		/**
		 * Serializes the value from the given type.
		 */
		private static function variableToString(value:*, type:String):String {
			switch (type) {
				case ("Number"):
				case ("String"):
				case ("Boolean"):
				case ("int"):
				case ("uint"):
					return String(value);
				case ("Date"):
					return dateFormatter.format(value);
			}
			return "";
		}
		
		/**
		 * Deserializes the value to the given type.
		 */
		private static function stringToVariable(value:String, type:String):* {
			switch (type) {
				case "String":
					return value;
				case "Boolean":
					return value.toLowerCase() == "true" || value == "1";
				case "Number":
					return parseFloat(value);
				case "int":
				case "uint":
					return parseInt(value);
				case "Date":
					return DateFormatter.parseDateString(value);
				default:
			}
			return null;
		}

	}
}

/**
 * A Group of ManifestEntry objects in a given Namespace
 */
class ManifestGroup {
	public var namespace:Namespace;
	public var entries:Array = []; // Type ManifestEntry
	
	public function ManifestGroup(namespace:Namespace) {
		this.namespace = namespace;
	}
	
	/**
	 * Adds a new ManifestEntry object.
	 */
	public function addEntry(entry:ManifestEntry):void {
		entry.parent = this;
		entries.push(entry);
	}
	
	/**
	 * Returns the ManifestEntry object with the given alias.
	 */
	public function getEntryByAlias(alias:String):ManifestEntry {
		for each (var entry:ManifestEntry in entries) {
			if (entry.alias == alias) return entry;
		}
		return null;
	}
	
	/**
	 * Returns the ManifestEntry object with the given fully qualified class name.
	 */
	public function getEntryByClassName(className:String):ManifestEntry {
		for each (var entry:ManifestEntry in entries) {
			if (entry.className == className) return entry;
		}
		return null;
	}
}

/**
 * ManifestEntry is a value object representing component nodes in a manifest file.
 */
class ManifestEntry {
	public var alias:String;
	public var className:String;
	public var parent:ManifestGroup;
	
	public function ManifestEntry(alias:String, className:String) {
		this.alias = alias;
		this.className = className;
	}
}