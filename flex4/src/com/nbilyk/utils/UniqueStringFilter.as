package com.nbilyk.utils {
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.utils.StringUtil;
	

	/**
	 * This class will watch a collection and provide a list of unique strings.
	 * Useful for things like suggestion drop downs. 
	 */

	public class UniqueStringFilter {
		private var _collection:IList;
		private var _uniqueResults:ArrayCollection;
		private var uniqueResultsDict:Dictionary = new Dictionary(); // Dictionary of lower(trim(str)) => count
		
		public var dataField:String;
		
		public function UniqueStringFilter() {
			_uniqueResults = new ArrayCollection();
			var s:Sort = new Sort();
			s.fields = [new SortField(null, true)];
			_uniqueResults.sort = s;
		}
		
		public function get collection():IList {
			return _collection;
		}
		public function set collection(value:IList):void {
			if (_collection) {
				_collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
			}
			_collection = value;
			if (_collection) {
				_collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
				uniqueResultsDict = new Dictionary();
				_uniqueResults.removeAll();
				addItems(_collection.toArray());
			}
		}
		private function collectionChangeHandler(event:CollectionEvent):void {
			if (!dataField) return;
			switch (event.kind) {
				case CollectionEventKind.ADD :
					addItems(event.items);
					break;
				case CollectionEventKind.REMOVE :
					removeItems(event.items);
					break;
				case CollectionEventKind.MOVE :
				case CollectionEventKind.REPLACE :
				case CollectionEventKind.UPDATE :
				case CollectionEventKind.REFRESH :
				case CollectionEventKind.RESET :
					// Rebuild the unique categories from scratch.
					uniqueResultsDict = new Dictionary();
					_uniqueResults.removeAll();
					addItems(_collection.toArray());
				
			}
		}
		
		private function removeItems(items:Array):void {
			var item:Object;
			var str:String;
			for each (item in items) {
				str = StringUtil.trim(item[dataField].toString()).toLowerCase();
				if (!str.length) continue;
				uniqueResultsDict[str]--;
				if (uniqueResultsDict[str] == 0) {
					// There are no more instances of this result, remove it from the list.
					var n:uint = _uniqueResults.length;
					for (var i:uint = 0; i < n; i++) {
						var uniqueStr:String = _uniqueResults.getItemAt(i) as String;
						if (str == StringUtil.trim(uniqueStr.toString()).toLowerCase()) {
							_uniqueResults.removeItemAt(i);
							break;
						}
					}
				}
			}
		}
		private function addItems(items:Array):void {
			for each (var item:Object in items) {
				var str:String = StringUtil.trim(item[dataField].toString()).toLowerCase();
				if (!str.length) continue;
				if (!uniqueResultsDict[str]) {
					uniqueResultsDict[str] = 1;
					_uniqueResults.addItem(item[dataField]);
				} else {
					uniqueResultsDict[str]++;
				}
			}
		}
		
		[Bindable(event="uniqueResultsChange")]
		public function get uniqueResults():ArrayCollection {
			return _uniqueResults;
		}
	}
}