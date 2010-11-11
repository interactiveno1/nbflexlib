package com.nbilyk.utils {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import mx.core.IVisualElement;
	import mx.core.IVisualElementContainer;
	import mx.utils.ObjectUtil;

	public class ListRecycler {
		
		[ArrayElementType("*")]
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
					if (oldComponent is DisplayObject) {
						var displayObject:DisplayObject = oldComponent as DisplayObject;
						if (oldComponent is IVisualElement && oldComponent.parent is IVisualElementContainer) {
							var p:IVisualElementContainer = IVisualElementContainer(oldComponent.parent);
							p.setElementIndex(oldComponent as IVisualElement, p.numElements - 1);
						} else if (oldComponent.parent != null) {
							var p2:DisplayObjectContainer = DisplayObjectContainer(oldComponent.parent);
							p2.setChildIndex(displayObject, p2.numChildren - 1);
						}
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
						if (displayObject is IVisualElement && displayObject.parent is IVisualElementContainer) {
							IVisualElementContainer(displayObject.parent).removeElement(IVisualElement(displayObject));
						} else {
							displayObject.parent.removeChild(displayObject);
						}
					}
				}
			}
			oldComponents = null;
		}
	}
}