package com.nbilyk.managers {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import mx.core.ApplicationGlobals;
	import mx.events.BrowserChangeEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.managers.BrowserManager;

	public class PrettyHistoryManager {
		public static var separator:String = "/";

		private static var _instance:PrettyHistoryManager;
		
		private var pendingQueryString:String;
		private var isLoadingState:Boolean;
		private var stateInvalidFlag:Boolean;
		
		private var logger:ILogger = Log.getLogger("com.nbilyk.managers.PrettyHistoryManager");

		public static function get instance():PrettyHistoryManager {
			if (!_instance) _instance = new PrettyHistoryManager(new SingletonEnforcer());
			return _instance;
		}

		public function PrettyHistoryManager(s:SingletonEnforcer) {
			super();

			if (_instance) throw new Error("Instance already exists.");
			if (!app.historyManagementEnabled) return;

			BrowserManager.getInstance().addEventListener(BrowserChangeEvent.BROWSER_URL_CHANGE, browserUrlChangeHandler);
			BrowserManager.getInstance().initForHistoryManager();
		}
		private function get app():Object {
			return ApplicationGlobals.application;
		}

		/**
		 *  An Array of objects that will save and load state information.
		 *  Each object must implement the IPrettyHistoryManagerClient interface.
		 */
		private var registeredObjects:Array = []; /* Type IPrettyHistoryManagerClient */
		
		private var fragmentSplit:Array = []; /* Type String */
		private var hasStateLoaded:Array = []; /* Type Boolean, parallel to fragmentSplit */


		/**
		 *  Registers an object with the PrettyHistoryManager.
		 *  The object must implement the IPrettyHistoryManagerClient interface.
		 *
		 *  @param obj Object to register.
		 *
		 *  @see mx.managers.IPrettyHistoryManagerClient
		 */
		public function register(client:IPrettyHistoryManagerClient):void {
			if (!app.historyManagementEnabled) return;
			unregister(client);
			registeredObjects.push(client);
			
			var split:Array = BrowserManager.getInstance().fragment.split(separator);
			if (split.length < client.getClientDepth() - 1) return;
			invalidateState();
		}
		/**
		 * @see PrettyHistoryManager.register
		 */
		public static function register(client:IPrettyHistoryManagerClient):void {
			PrettyHistoryManager.instance.register(client);
		}
		
		/**
		 * Unregisters an object with the PrettyHistoryManager.
		 * @param obj IPrettyHistoryManagerClient to unregister.
		 * @return The index of the client. (-1 if not found)
		 */
		public function unregister(client:IPrettyHistoryManagerClient):int {
			if (!app.historyManagementEnabled) return -1;

			var index:int = registeredObjects.indexOf(client);
			if (index != -1) registeredObjects.splice(index, 1);
			return index;
		}
		
		/**
		 * @see PrettyHistoryManager.unregister
		 */
		public static function unregister(client:IPrettyHistoryManagerClient):void {
			PrettyHistoryManager.instance.unregister(client);
		}

		/**
		 *  Saves the application's current state to the URL.
		 */
		public function save():void {
			if (!app.historyManagementEnabled || isLoadingState) return;

			var clientValues:Array = [""];

			// Call saveState() on every registered object to get its state information.
			for each (var registeredObject:IPrettyHistoryManagerClient in registeredObjects) {
				clientValues[registeredObject.getClientDepth()] = registeredObject.saveState();
			}

			if (clientValues.length) {
				pendingQueryString = clientValues.join(separator);
				app.callLater(submitQuery);
			}
		}
		
		/**
		 * @see PrettyHistoryManager.save
		 */
		public static function save():void {
			PrettyHistoryManager.instance.save();
		}

		/**
		 *  Reloads the _history iframe with the history SWF.
		 */
		private function submitQuery():void {
			if (pendingQueryString) {
				BrowserManager.getInstance().setFragment(pendingQueryString);
				pendingQueryString = null;
				app.resetHistory = true;
			}
		}
		
		//----------------------
		//  Event handlers
		//----------------------

		/**
		 *  The browser's url has changed.
		 */
		public function browserUrlChangeHandler(event:BrowserChangeEvent):void {
			fragmentSplit = BrowserManager.getInstance().fragment.split(separator);
			hasStateLoaded = new Array(fragmentSplit.length);
			invalidateState();
		}
		
		//--------------------------
		// Validation methods
		//--------------------------
		
		public function invalidateState():void {
			stateInvalidFlag = true;
			app.callLater(validateState);
		}
		
		private function validateState():void {
			if (stateInvalidFlag) {
				stateInvalidFlag = false;
				if (!app.historyManagementEnabled) return;
				isLoadingState = true;
				var fragmentSplitL:uint = fragmentSplit.length;
				for each (var client:IPrettyHistoryManagerClient in registeredObjects) {
					if (fragmentSplitL < client.getClientDepth() - 1) continue;
					var clientDepth:uint = client.getClientDepth();
					if (!hasStateLoaded[clientDepth]) {
						hasStateLoaded[clientDepth] = true;
						var newState:String = fragmentSplit[clientDepth];
						if (client.saveState() != newState) client.loadState(newState);
					}
				}
				isLoadingState = false;
			}
		}
		
		
		//----------------------
		// Utility methods
		//----------------------
		
		/**
		 * Given a display object, looks up the ancestry to try to determine the client depth automatically.
		 */
		public static function calculateClientDepth(client:DisplayObject):uint {
			var p:DisplayObjectContainer = client.parent;
			while (p && p != p.stage) {
				if (p is IPrettyHistoryManagerClient) return IPrettyHistoryManagerClient(p).getClientDepth() + 1;
				p = p.parent;
			}
			return 1;
		}
		
	}
}

class SingletonEnforcer {}