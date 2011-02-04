package com.nbilyk.controls {
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.Sort;
	import mx.core.IVisualElement;
	import mx.events.CollectionEvent;
	
	import spark.components.Group;
	import spark.layouts.VerticalLayout;

	public class MethodDataGroup extends Group {

		protected var resetList:Boolean;
		protected var currentComponents:Vector.<IVisualElement>;
		protected var collectionView:ListCollectionView;

		private var _dataProvider:*;
		private var _filterFunction:Function;
		private var _sort:Sort;
		private var _itemCreationFunction:Function;
		private var componentDict:Dictionary = new Dictionary(); // Type item:* => IVisualElement

		// Validation properties
		private var listIsValidFlag:Boolean;

		public function MethodDataGroup() {
			super();
			layout = new VerticalLayout(); // Default
		}

		//-------------------------------------------
		// Getters / Setters
		//-------------------------------------------

		public function get dataProvider():* {
			return _dataProvider;
		}

		public function set dataProvider(value:*):void {
			if (collectionView) {
				collectionView.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
			}
			_dataProvider = value;
			
			var collection:IList;
			
			if (value is IList) {
				collection = value;
			} else if (value is Array) {
				collection = new ArrayList(value);
			} else {
				collection = new ArrayList();
				for each (var item:* in value) {
					collection.addItem(item);
				}
			}
			
			collectionView = new ListCollectionView(collection);
			if (_filterFunction != null)
				collectionView.filterFunction = _filterFunction;
			if (_sort != null)
				collectionView.sort = _sort;
			collectionView.refresh();
			collectionView.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
			
			invalidateList();
		}
		
		/**
		 * Returns the sorted and filtered collection wrapper to the dataProvider.
		 */
		public function getCollectionView():ListCollectionView {
			return collectionView;
		}

		private function collectionChangeHandler(event:CollectionEvent):void {
			invalidateList();
		}

		public function get filterFunction():Function {
			return _filterFunction;
		}

		public function set filterFunction(filterFunction:Function):void {
			_filterFunction = filterFunction;
			if (collectionView) {
				collectionView.filterFunction = _filterFunction;
				collectionView.refresh();
			}
		}

		public function get sort():Sort {
			return _sort;
		}

		public function set sort(sort:Sort):void {
			_sort = sort;
			if (collectionView) {
				collectionView.sort = sort;
				collectionView.refresh();
			}
		}

		/**
		 * The method with which to create the child elements of this group.
		 * createItemFunction must take a single argument that is the element in the dataProvider and return a visual element.
		 * createItemFunction(item:*):IVisualElement
		 */
		public function get itemCreationFunction():Function {
			return _itemCreationFunction;
		}

		public function set itemCreationFunction(value:Function):void {
			if (_itemCreationFunction == value)
				return; // no-op
			_itemCreationFunction = value;
			resetList = true;
			invalidateList();
		}

		//---------------------------------------
		// Validation / invalidation
		//---------------------------------------

		override protected function commitProperties():void {
			super.commitProperties();
			if (!listIsValidFlag)
				validateList();
		}

		public function invalidateList():void {
			listIsValidFlag = false;
			invalidateProperties();
		}

		protected function validateList():void {
			listIsValidFlag = true;
			var item:*;
			var i:uint;
			
			var oldComponents:Vector.<IVisualElement> = currentComponents;
			if (resetList) {
				removeAllElements();
				oldComponents = new Vector.<IVisualElement>();
				componentDict = new Dictionary();
			}
			resetList = false;
			currentComponents = new Vector.<IVisualElement>();
			
			var newComponentDict:Dictionary = new Dictionary();
			if (itemCreationFunction != null) {
				i = 0;
				for each (item in collectionView) {
					var component:IVisualElement = componentDict[item] as IVisualElement;
					if (component == null) {
						component = itemCreationFunction(item);
						if (!component) continue; 
						addElement(component);
					} else {
						setElementIndex(component, i);
					}
					newComponentDict[item] = component;
					currentComponents.push(component);
					i++;
				}
			}
			
			// Search through the old components and remove ones that are no longer used.
			for each (var oldComponent:IVisualElement in componentDict) {
				if (currentComponents.indexOf(oldComponent) == -1) {
					removeElement(oldComponent);
				}
			}
			componentDict = newComponentDict;
		}
		
		public function reset():void {
			resetList = true;
			invalidateList();
		}
	}
}