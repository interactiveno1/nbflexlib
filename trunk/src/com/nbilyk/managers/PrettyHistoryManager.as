package com.nbilyk.managers {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.external.ExternalInterface;
	
	import mx.core.ApplicationGlobals;
	import mx.events.BrowserChangeEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.managers.BrowserManager;

	public class PrettyHistoryManager {
		public static var separator:String = "/";

		private static var _instance:PrettyHistoryManager;
		
		private var pendingFragment:String;
		private var explicitFragment:String;
		private var isLoadingState:Boolean;
		private var stateInvalidFlag:Boolean;
		private var noJs:Boolean;
		
		private var logger:ILogger = Log.getLogger("com.nbilyk.managers.PrettyHistoryManager");

		public static function get instance():PrettyHistoryManager {
			if (!_instance) _instance = new PrettyHistoryManager(new SingletonEnforcer());
			return _instance;
		}

		public function PrettyHistoryManager(s:SingletonEnforcer) {
			super();

			if (_instance) throw new Error("Instance already exists.");

			BrowserManager.getInstance().addEventListener(BrowserChangeEvent.BROWSER_URL_CHANGE, browserUrlChangeHandler);
			BrowserManager.getInstance().initForHistoryManager();
			
			if (!ExternalInterface.available || !ExternalInterface.call("eval", "window.location.href")) {
				logger.info("Javascript unavailable. Only working with explicitly set fragments.");
				noJs = true;
			}
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
				pendingFragment = clientValues.join(separator);
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
			if (pendingFragment) {
				//logger.debug("Set fragment: " + pendingFragment);
				BrowserManager.getInstance().setFragment(pendingFragment);
				pendingFragment = null;				
				app.resetHistory = true;			
			}
		}
		
		/**
		 * Returns the browser url fragment after the hash.
		 * Use this instead of BrowserManager.getInstance().fragment
		 * 
		 * Fix to work with Chrome
		 * If no javascript, use the explicit fragment set via setFragment().
		 */
		public function getFragment():String {
			if (noJs) return explicitFragment;
			if (ExternalInterface.available) {
				var url:String = ExternalInterface.call("eval", "window.location.href");
				if (url) {
					var urlSplit:Array = url.split("#");
					if (urlSplit.length >= 2) return urlSplit[1];
				} else {
					noJs = true;
					return explicitFragment;
				}
			} else {
				noJs = true;
				return explicitFragment;
			}
			return "";
		}
		
		/**
		 * A helper method to set the BrowserManager fragment that doesn't result in mayhem.
		 */
		public function setFragment(fragment:String):void {
			explicitFragment = fragment;
			//logger.debug("Set fragment: " + fragment);
			BrowserManager.getInstance().setFragment(fragment);
			pendingFragment = null;
			app.resetHistory = true;
			BrowserManager.getInstance().dispatchEvent(new BrowserChangeEvent(BrowserChangeEvent.BROWSER_URL_CHANGE));
		}
		
		/**
		 * Triggers an invalidation and sets all states to be pending for update.
		 */
		public function refresh():void {
			pendingFragment = null;
			fragmentSplit = getFragment().split(separator);
			hasStateLoaded = new Array(fragmentSplit.length);
			invalidateState();
		}
		
		//----------------------
		//  Event handlers
		//----------------------

		/**
		 *  The browser's url has changed.
		 */
		private function browserUrlChangeHandler(event:BrowserChangeEvent):void {
			if (!app.historyManagementEnabled) return;
			refresh();
			//logger.debug("BrowserURLCHange handler: " + BrowserManager.getInstance().fragment + " : " +  fragmentSplit);
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
					var clientDepth:uint = client.getClientDepth();
					if (clientDepth >= fragmentSplitL) {
						client.loadState("");
						continue;
					}
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
		
		public function resetAllStates():void {
			isLoadingState = true;
			registeredObjects.sort(reverseSortOnClientDepth);
			for each (var client:IPrettyHistoryManagerClient in registeredObjects) {
				client.loadState("");
			}
			isLoadingState = false;
			setFragment("/");
		}

		private function reverseSortOnClientDepth(a:IPrettyHistoryManagerClient, b:IPrettyHistoryManagerClient):Number {
			var aDepth:uint = a.getClientDepth();
			var bDepth:uint = b.getClientDepth();

			if (aDepth > bDepth) {
				return -1;
			} else if (aDepth < bDepth) {
				return 1;
			} else {
				return 0;
			}
		}

		
	}
}

class SingletonEnforcer {}