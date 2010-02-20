package com.nbilyk.managers {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	
	import mx.core.ApplicationGlobals;
	import mx.core.IUIComponent;
	import mx.events.BrowserChangeEvent;
	import mx.events.FlexEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.managers.BrowserManager;
	
	/**
	 * Triggered after the state is validated.  (All clients have loaded state.)
	 */
	[Event(name="updateComplete", type="mx.events.FlexEvent")]
	
	/**
	 * Triggered when the URL has changed, either through a browserURLChange event, or by a call to setFragment.
	 */
	[Event(name="urlChanged", type="mx.events.FlexEvent")]
	
	public class PrettyHistoryManager extends EventDispatcher {
		public static var separator:String = "/";

		private static var _instance:PrettyHistoryManager;
		
		private var pendingFragment:String;
		private var isLoadingState:Boolean;
		private var stateInvalidFlag:Boolean;
		private var noJs:Boolean;
		private var fragmentIsInvalid:Boolean = true;
		private var fragment:String;
		
		/**
		 *  An Array of objects that will save and load state information.
		 *  Each object must implement the IPrettyHistoryManagerClient interface.
		 */
		private var registeredObjects:Array = []; /* Type IPrettyHistoryManagerClient */
		
		private var fragmentSplit:Array = []; /* Type String */
		private var hasStateLoaded:Array = []; /* Type Boolean, parallel to fragmentSplit */
		
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
		 * Causes the client to automatically be registered and unregistered as it's added and removed from the stage. 
		 * @param client The DisplayObject to watch.
		 */
		public static function registerDisplayObjectClient(client:IPrettyHistoryManagerClient):void {
			var dO:DisplayObject = DisplayObject(client);
			dO.addEventListener(Event.ADDED_TO_STAGE, clientAddedToStageHandler, false, 0, true);
			dO.addEventListener(Event.REMOVED_FROM_STAGE, clientRemovedFromStageHandler, false, 0, true);
			if (dO.stage) register(client);
		}
		
		/**
		 * Unregisters and removes listeners to a client added through <code>registerDisplayObjectClient</code>.
		 * @param client
		 * @see #registerDisplayObjectClient
		 */
		public static function unregisterDisplayObjectClient(client:IPrettyHistoryManagerClient):void {
			var dO:DisplayObject = DisplayObject(client);
			dO.removeEventListener(Event.ADDED_TO_STAGE, clientAddedToStageHandler);
			dO.removeEventListener(Event.REMOVED_FROM_STAGE, clientRemovedFromStageHandler);
			unregister(client);
		}
		
		private static function clientAddedToStageHandler(event:Event):void {
			register(IPrettyHistoryManagerClient(event.currentTarget));
		}
		private static function clientRemovedFromStageHandler(event:Event):void {
			unregister(IPrettyHistoryManagerClient(event.currentTarget));
		}


		/**
		 *  Registers an IPrettyHistoryManagerClient with the PrettyHistoryManager.
		 *
		 *  @param client
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
		 * @see #register
		 */
		public static function register(client:IPrettyHistoryManagerClient):void {
			instance.register(client);
		}
		
		/**
		 * Unregisters an object with the PrettyHistoryManager.
		 * @param obj IPrettyHistoryManagerClient to unregister.
		 * @return Returns <code>true</code> if the client was found. 
		 */
		public function unregister(client:IPrettyHistoryManagerClient, unregisterChildren:Boolean = false):Boolean {
			if (!app.historyManagementEnabled) return false;
			
			var index:int = registeredObjects.indexOf(client);
			if (index == -1) return false;
			registeredObjects.splice(index, 1);
			
			var clientDepth:int = client.getClientDepth();
			if (unregisterChildren) {
				var n:uint = registeredObjects.length;
				for (var i:uint = 0; i < n; i++) {
					var registeredObject:IPrettyHistoryManagerClient = registeredObjects[i];
					if (registeredObject.getClientDepth() >= clientDepth) {
						registeredObjects.splice(i, 1);
						i--; n--;
					}
				}
			}
			
			return true;
		}
		
		public static function unregisterDisplayTree(root:DisplayObjectContainer):void {
			instance.unregisterDisplayTree(root);
		}
		
		/**
		 * Removes all clients that descend from a given DisplayObject.
		 * @param root The root of the tree to remove.
		 */
		public function unregisterDisplayTree(root:DisplayObjectContainer):void {
			if (!root) return;
			var n:uint = registeredObjects.length;
			for (var i:uint = 0; i < n; i++) {
				var registeredObject:IPrettyHistoryManagerClient = registeredObjects[i];
				if (registeredObject is DisplayObject && owns(root, DisplayObject(registeredObject))) {
					registeredObjects.splice(i, 1);
					i--; n--;
				}
			}
		}
		
		/**
		 * @see PrettyHistoryManager#unregister
		 */
		public static function unregister(client:IPrettyHistoryManagerClient):void {
			instance.unregister(client);
		}

		/**
		 * Saves the application's current state to the URL.
		 */
		public function save():void {
			if (!app.historyManagementEnabled || isLoadingState) return;
			var clientValues:Array = [""]; /* Type String */

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
		 * @see #save
		 */
		public static function save():void {
			instance.save();
		}

		/**
		 *  Reloads the _history iframe with the history SWF.
		 */
		private function submitQuery():void {
			if (pendingFragment) {
				if (pendingFragment.substr(-1, 1) != separator) pendingFragment += separator; // /foo/bar is the same as /foo/bar/
				setFragment(pendingFragment, false);
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
			if (fragmentIsInvalid) {
				fragment = calculateFragment();
				fragmentIsInvalid = false;
			}
			return fragment;
		}
		private function calculateFragment():String {
			if (noJs) return fragment;
			if (ExternalInterface.available) {
				var url:String = ExternalInterface.call("eval", "window.location.href");
				if (url) {
					var urlSplit:Array = url.split("#");
					if (urlSplit.length >= 2) return urlSplit[1];
				} else {
					noJs = true;
					return fragment;
				}
			} else {
				noJs = true;
				return fragment;
			}
			return "";
		}
		
		/**
		 * A helper method to set the BrowserManager fragment that doesn't result in mayhem.
		 * @var doRefresh If true, invalidates the state and therefore, calls loadState on all registered objects.
		 */
		public function setFragment(newFragment:String, doRefresh:Boolean = true):void {
			if (newFragment.substr(-1, 1) != separator) newFragment += separator; // /foo/bar is the same as /foo/bar/
			fragment = newFragment;
			BrowserManager.getInstance().setFragment(newFragment);
			pendingFragment = null;
			app.resetHistory = true;
			if (doRefresh) refresh();
			dispatchEvent(new FlexEvent(FlexEvent.URL_CHANGED));
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
			fragmentIsInvalid = true;
			refresh();
			dispatchEvent(new FlexEvent(FlexEvent.URL_CHANGED));
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
				dispatchEvent(new FlexEvent(FlexEvent.UPDATE_COMPLETE));
				isLoadingState = false;
			}
		}
		
		
		//----------------------
		// Utility methods
		//----------------------
		
		/**
		 * Checks if <code>child</code> is a descendant of <code>parent</code>
		 * @param parent
		 * @param child
		 */
		protected function owns(parent:DisplayObjectContainer, child:DisplayObject):Boolean {
			if (child == parent) return true;
			var p:DisplayObjectContainer = child.parent;
			try {
				while (p) {
					if (p == parent) return true;
					if (p is IUIComponent) p = IUIComponent(p).owner;
					else p = p.parent;
				}
			} catch (e:SecurityError) {
				// You can't own what you don't have access to.
				return false;
			}
			return false;
		}
		
		/**
		 * Given a display object, looks up the ancestry to try to determine the client depth automatically.
		 */
		public static function calculateClientDepth(client:DisplayObject):uint {
			var p:DisplayObjectContainer = client.parent;
			try {
				while (p && p != p.stage) {
					if (p is IPrettyHistoryManagerClient) return IPrettyHistoryManagerClient(p).getClientDepth() + 1;
					if (p is IUIComponent) p = IUIComponent(p).owner;
					else p = p.parent;
				}
			} catch (error:SecurityError) {}
			return 1;
		}
		
		/**
		 * Reset all states to their initial state.
		 */
		public function resetAllStates():void {
			isLoadingState = true;
			registeredObjects.sort(reverseSortOnClientDepth);
			for each (var client:IPrettyHistoryManagerClient in registeredObjects) {
				client.loadState("");
			}
			isLoadingState = false;
			setFragment(separator);
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
		
		/**
		 * Returns true if actionB contains actionA. 
		 * e.g. ("/foo/bar", "/foo/bar/sha") == true
		 * ("/foo/sha", "/foo/bar") == false
		 */
		public static function isActionAInActionB(actionA:String, actionB:String):Boolean {
			if (!actionA || !actionB) return false;
			if (actionB.substr(-1, 1) != separator) actionB += separator; // /foo/bar is the same as /foo/bar/
			
			var actionASplit:Array = actionA.split(separator);
			var actionBSplit:Array = actionB.split(separator);
			
			if (actionASplit.length > actionBSplit.length) return false;
			var n:uint = actionASplit.length;
			for (var i:uint = 0; i < n; i++) {
				if (actionASplit[i] != actionBSplit[i]) return false;
			}
			return true;
		}
	}
}

class SingletonEnforcer {}