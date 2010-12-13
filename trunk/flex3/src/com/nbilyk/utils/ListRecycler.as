package com.nbilyk.utils {
	import flash.display.DisplayObject;
	
	public class ListRecycler {
		
		private var oldComponents:*;
		
		/**
		 * @param oldComponents An iteratable object of the components we're recycling.
		 */
		public function ListRecycler(oldComponentsVal:* /* Type * */) {
			oldComponents = oldComponentsVal;
		}
		
		/**
		 * Given a value object, this will see if there is a recycled item that
		 * @param vO The value object to search for in the old components.
		 * @param propName The name of the property on the old components that correspond to the Value Object. 
		 */
		public function getRecycledComponent(vO:*, propName:String = "data"):* {
			for each (var oldComponent:* in oldComponents) {
				if (oldComponent[propName] == vO) {
					var displayObject:DisplayObject = oldComponent as DisplayObject;
					if (displayObject && displayObject.parent) {
						displayObject.parent.setChildIndex(displayObject, displayObject.parent.numChildren - 1);
					}
					return oldComponent;
				}
			}
			return null;
		}
		
		/**
		 * @param newComponents An iteratable object of the new components we shouldn't remove.
		 */
		public function removeOldComponents(newComponents:* /* Type * */):void {
			for each (var oldComponent:* in oldComponents) {
				if (newComponents.indexOf(oldComponent) == -1) {
					var displayObject:DisplayObject = oldComponent as DisplayObject;
					if (displayObject && displayObject.parent) {
						displayObject.parent.removeChild(displayObject);
					}
				}
			}
			oldComponents = null;
		}
	}
}