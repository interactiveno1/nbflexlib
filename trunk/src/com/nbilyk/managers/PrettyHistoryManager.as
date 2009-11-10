package com.nbilyk.managers {
	import mx.core.Application;
	import mx.core.ApplicationGlobals;
	import mx.events.BrowserChangeEvent;
	import mx.managers.BrowserManager;

	public class PrettyHistoryManager {
		public static var separator:String = "/";

		private static var _instance:PrettyHistoryManager;
		
		private var pendingQueryString:String;

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
		private function get app():Application {
			return Application(ApplicationGlobals.application);
		}

		/**
		 *  An Array of objects that will save and load state information.
		 *  Each object must implement the IPrettyHistoryManagerClient interface.
		 */
		private var registeredObjects:Array = []; /* Type IPrettyHistoryManagerClient */


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
			client.loadState(split[client.getClientDepth()]);
		}
		/**
		 * @see PrettyHistoryManager.register
		 */
		public static function register(client:IPrettyHistoryManagerClient):void {
			PrettyHistoryManager.instance.register(client);
		}
		
		/**
		 *  Unregisters an object with the PrettyHistoryManager.
		 *  @param obj IPrettyHistoryManagerClient to unregister.
		 */
		public function unregister(client:IPrettyHistoryManagerClient):void {
			if (!app.historyManagementEnabled) return;

			var index:int = registeredObjects.indexOf(client);
			registeredObjects.splice(index, 1);
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
			if (!app.historyManagementEnabled) return;

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
		 *  @private
		 *  Reloads the _history iframe with the history SWF.
		 */
		private function submitQuery():void {
			if (pendingQueryString) {
				BrowserManager.getInstance().setFragment(pendingQueryString);
				pendingQueryString = null;
				app.resetHistory = true;
			}
		}

		//--------------------------------------------------------------------------
		//  Event handlers
		//--------------------------------------------------------------------------

		/**
		 *  Loads state information.
		 *
		 *  @param stateVars State information.
		 */
		public function browserUrlChangeHandler(event:BrowserChangeEvent):void {
			if (!app.historyManagementEnabled) return;

			var split:Array = BrowserManager.getInstance().fragment.split(separator);
			for each (var client:IPrettyHistoryManagerClient in registeredObjects) {
				if (split.length < client.getClientDepth() - 1) continue;
				client.loadState(split[client.getClientDepth()]);
			}
		}
	}
}

class SingletonEnforcer {}