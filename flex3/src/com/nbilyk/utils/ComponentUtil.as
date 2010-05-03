/**
 * @author Nick Bilyk http://www.nbilyk.com
 * @author Judah Frangipane http://www.judahfrangipane.com
 */
package com.nbilyk.utils {
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.core.Container;
	import mx.core.ContainerCreationPolicy;
	import mx.events.PropertyChangeEvent;
	
	public class ComponentUtil {
		
		/**
		 * @return Returns all required properties that weren't set. 
		 * Note that int, uint, and Boolean data types shouldn't be required, they automatically have default values.
		 * Make sure in your compiler arguments you add the option:
		 * -keep-as3-metadata+=Required
		 */
		[ArrayElementType("XML")]
		public static function getMissingPropertyNames(obj:Object):Array {
			var metadata:XMLList = describeType(obj)..metadata.(@name == "Required");
			
			var unsetProperties:Array = [];
			for each (var metadataItem:XML in metadata) {
				var variableOrAccessor:XML = metadataItem.parent();
				if (variableOrAccessor.@type == "Number") {
					// Note, uint and int cannot be NaN, only a Number can be.
					if (isNaN(obj[variableOrAccessor.@name])) {
						unsetProperties.push(variableOrAccessor.@name.toString());
					}
				} else {
					if (obj[variableOrAccessor.@name] == null) {
						unsetProperties.push(variableOrAccessor.@name.toString());
					}
				}
			}
			return unsetProperties;
		}
		/**
		 * Inspects an object and makes sure all properties are set.
		 * Note that int, uint, and Boolean data types shouldn't be required, they automatically have default values.
		 * @throws ArgumentError if one or more required properties weren't set. 
		 */
		public static function checkRequired(obj:Object):void {
			var names:Array = getMissingPropertyNames(obj);
			if (names.length) throw new ArgumentError("The following properties are required: " + names.join(", "));
		}
		
		private static var pendingDict:Dictionary = new Dictionary(true); // A Dictionary of Component => [propertyName1, propertyName2]
		
		/**
		 * Call this method on a Container's preinitialize method to postpone creation of children until all [Required] properties have been set.
		 */
		public static function createOnRequired(container:Container):void {
			if (container.initialized) throw new ArgumentError("This container is already initialized.");
			var names:Array = getMissingPropertyNames(container);
			if (!names.length) return;
			container.creationPolicy = ContainerCreationPolicy.NONE;
			pendingDict[container] = names;
			for each (var name:String in names) {
				if (!ChangeWatcher.canWatch(container, name)) {
					throw new ArgumentError("All required properties must be bindable.");
				}
				ChangeWatcher.watch(container, name, bindablePropertySetHandler);
			}
		}
		private static function bindablePropertySetHandler(event:PropertyChangeEvent):void {
			var names:Array = pendingDict[event.currentTarget] as Array;
			if (!names) return;
			var index:int = names.indexOf(event.property.toString());
			if (index != -1) names.splice(index, 1);
			pendingDict[event.currentTarget] = names;
			if (!names.length) {
				delete pendingDict[event.currentTarget];
				var container:Container = Container(event.currentTarget);
				container.invalidateProperties();
				container.createComponentsFromDescriptors();
			}
		}
	}
}