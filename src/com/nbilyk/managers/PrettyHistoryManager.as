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
		public static var prefix:String = separator;
		
		private static var _instance:PrettyHistoryManager;
		
		private var pendingFragment:String;
		private var isLoadingState:Boolean;
		private var noJs:Boolean;
		private var _fragment:String = "";
		
		// Validation flags
		private var stateIsValidFlag:Boolean = true;
		private var fragmentIsValidFlag:Boolean;
		
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
			
			if (!checkJavascriptEnabled()) {
				logger.info("Javascript unavailable. Only working with explicitly set fragments.");
			}
		}
		
		/**
		 * Returns true if javascript is enabled.
		 */
		public function checkJavascriptEnabled():Boolean {
			try {
				noJs = !ExternalInterface.available || !ExternalInterface.call("eval", "window.location.href");
			} catch (error:Error) {
				noJs = true;
			}
			return !noJs;
		}
		
		/**
		 * A way to get the Application without requiring a the Application dependency tree.
		 */
		private function get app():Object {
			return ApplicationGlobals.application;
		}
		
		/**
		 * @see mx.core.Application#callLater
		 */
		private function callLater(method:Function, args:Array = null):void {
			app.callLater(method, args);
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
		
		/**
		 * @see #unregisterDisplayTree
		 */
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
		 * @see #save
		 */
		public static function save():void {
			instance.save();
		}
		
		/**
		 * Saves the application's current state to the URL.
		 */
		public function save():void {
			if (!app.historyManagementEnabled || isLoadingState) return;
			pendingFragment = getSavedStateFragment();
			callLater(submitQuery);
		}
		
		/**
		 * For all clients between the depths of <code>startIndex</code> and <code>endIndex</code>
		 * this will call saveState() on them and build a fragment url between the two indices.
		 * If there are no registered clients within range, this will return null.
		 */
		protected function getSavedStateFragment(startIndex:uint = 0, endIndex:uint = uint.MAX_VALUE):String {
			if (startIndex > endIndex) return "";
			var clientValues:Array = []; /* Type String */

			for each (var registeredObject:IPrettyHistoryManagerClient in registeredObjects) {
				var clientDepth:uint = registeredObject.getClientDepth();
				if (clientDepth < startIndex || clientDepth >= endIndex) continue;
				var n:uint = registeredObject.getParamCount();
				var saveValues:Array = registeredObject.saveState();
				saveValues.length = n;
				for (var i:uint = 0; i < n && i < endIndex - clientDepth; i++) {
					clientValues[clientDepth - startIndex + i] = saveValues[i];
				}
			}
			if (!clientValues.length) return null;
			return clientValues.join(separator);
		}

		/**
		 *  Reloads the _history iframe with the history SWF.
		 */
		private function submitQuery():void {
			if (pendingFragment != null) {
				setFragment(pendingFragment, false);
			}
		}
		
		/**
		 * Returns the browser url fragment after the hash.
		 * Use this instead of BrowserManager.getInstance().fragment
		 * 
		 * If the history.js is unavailable, this will use the explicitly set fragment set via setFragment().
		 */
		public function getFragment():String {
			if (!fragmentIsValidFlag) {
				fragment = calculateFragment();
			}
			return fragment;
		}
		
		/**
		 * Calculates the fragment from the url. 
		 * Fix to work with Chrome
		 * If the history.js is unavailable, this will use the explicitly set fragment set via setFragment().
		 */
		private function calculateFragment():String {
			if (noJs) return fragment;
			if (ExternalInterface.available) {
				var url:String = ExternalInterface.call("eval", "window.location.href");
				if (url) {
					var urlSplit:Array = url.split("#" + prefix);
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
		public function setFragment(newFragment:String = "", doRefresh:Boolean = true):void {
			pendingFragment = null;
			newFragment = sanitizeFragment(newFragment);
			fragment = newFragment;
			BrowserManager.getInstance().setFragment(prefix + newFragment);
			app.resetHistory = true;
			if (doRefresh) refresh();
			dispatchEvent(new FlexEvent(FlexEvent.URL_CHANGED));
		}
		
		/**
		 * Splices in a fragment into the existing fragment. 
		 * e.g. If, after a saveState() on the clients, the fragment is a/b/c/d/e, 
		 * and this method is called with ("g/h", 3, 5, true) then the new fragment will be a/b/g/h/e, 
		 * and then on the next frame loadState will be called on the clients with client depths between 3 and 5.
		 * 
		 * @var fragmentSection The fragment section to splice into the url after a fresh save. 
		 * @var startIndex The inclusive start index of the subsection.
		 * @var endIndex The exclusive end index of the subsection.
		 * @var doRefresh If true, invalidates the state and therefore calls loadState on all registered objects.
		 * @see #setFragment
		 */
		public function setFragmentSection(fragmentSection:String = "", startIndex:uint = 0, endIndex:uint = uint.MAX_VALUE, doRefresh:Boolean = true):void {
			if (startIndex > endIndex) return;
			fragmentSection = sanitizeFragment(fragmentSection);
			var sectionA:String = getSavedStateFragment(0, startIndex) || "";
			var sectionB:String = getSavedStateFragment(endIndex) || "";
			var newFragment:String = sectionA + separator + fragmentSection + separator + sectionB;
			setFragment(newFragment, doRefresh);
		}
		
		public function reset():void {
			/* isLoadingState = true;
			for each (var client:IPrettyHistoryManagerClient in registeredObjects) {
				client.loadState(new Array(client.getParamCount()));
			}
			isLoadingState = false; */
			setFragment();
		}
		
		/**
		 * Triggers an invalidation and sets all states to be pending for update.
		 * This is called internally on a browser url change and on an explicit setFragment call.
		 */
		public function refresh():void {
			fragmentSplit = getFragment().split(separator);
			hasStateLoaded = new Array(fragmentSplit.length);
			invalidateState();
		}
		
		private function get fragment():String {
			return _fragment;
		}
		private function set fragment(value:String):void {
			_fragment = value;
			fragmentIsValidFlag = true;
		}
		
		//----------------------
		//  Event handlers
		//----------------------

		/**
		 *  The browser's url has changed.
		 */
		private function browserUrlChangeHandler(event:BrowserChangeEvent):void {
			if (!app.historyManagementEnabled) return;
			fragmentIsValidFlag = false;
			refresh();
			dispatchEvent(new FlexEvent(FlexEvent.URL_CHANGED));
		}
		
		//--------------------------
		// Validation methods
		//--------------------------
		
		public function invalidateState():void {
			stateIsValidFlag = false;
			app.callLater(validateState);
		}
		
		/**
		 * Iterates over the pretty history manager clients and calls loadState on the ones that their
		 * url fragment section has changed.
		 * Dispatches an FlexEvent.UPDATE_COMPLETE event.
		 */
		private function validateState():void {
			if (!stateIsValidFlag) {
				stateIsValidFlag = true;
				if (!app.historyManagementEnabled) return;
				isLoadingState = true;
				var fragmentSplitL:uint = fragmentSplit.length;
				for each (var client:IPrettyHistoryManagerClient in registeredObjects) {
					var clientDepth:uint = client.getClientDepth();
					if (clientDepth >= fragmentSplitL) {
						// The url fragment ends before this client begins.
						client.loadState(new Array(client.getParamCount()));
						continue;
					}
					if (!hasStateLoaded[clientDepth]) {
						hasStateLoaded[clientDepth] = true;
						var clientParamCount:uint = client.getParamCount();
						var newArgs:Array = fragmentSplit.slice(clientDepth, clientDepth + clientParamCount);
						newArgs.length = clientParamCount;
						var previousArgs:Array = client.saveState();
						previousArgs.length = clientParamCount;
						
						// Check if the parameters to the client have changed.
						var hasChanged:Boolean = false;
						for (var i:uint = 0; i < clientParamCount; i++) {
							if (newArgs[i] != previousArgs[i]) {
								hasChanged = true;
								break;
							}
						}
						if (hasChanged) client.loadState(newArgs);
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
		 * Given a display object, walks up the ancestry to try to determine the client depth automatically.
		 */
		public static function calculateClientDepth(client:DisplayObject):uint {
			var p:DisplayObjectContainer = client.parent;
			try {
				while (p && p != p.stage) {
					if (p is IPrettyHistoryManagerClient) {
						var prettyClient:IPrettyHistoryManagerClient = IPrettyHistoryManagerClient(p);
						return prettyClient.getClientDepth() + prettyClient.getParamCount();
					}
					if (p is IUIComponent) p = IUIComponent(p).owner;
					else p = p.parent;
				}
			} catch (error:SecurityError) {}
			return 0;
		}
		
		/**
		 * Returns true if actionB contains actionA. 
		 * e.g. ("foo/bar", "foo/bar/sha") == true
		 * ("foo/sha", "foo/bar") == false
		 * ("foo/bar", "mep/foo/bar/sha", 1) == true
		 * @var actionA The fragment or partial fragment to check if exists in actionB
		 * @var actionB The entire fragment to search 
		 */
		public static function isActionAInActionB(actionA:String, actionB:String):Boolean {
			if (!actionA || !actionB) return false;
			actionA = sanitizeFragment(actionA);
			actionB = sanitizeFragment(actionB);
			
			var actionASplit:Array = actionA.split(separator);
			var actionBSplit:Array = actionB.split(separator);
			
			var n:uint = actionASplit.length;
			if (n > actionBSplit.length) return false;
			for (var i:uint = 0; i < n; i++) {
				if (actionASplit[i] != actionBSplit[i]) return false;
			}
			return true;
		}
		
		/**
		 * Takes an action and returns a slice of it based on the separators.
		 * @var action The action to split up by its separators and slice.
		 * @var startIndex the starting index of the slice.
		 * @var endIndex the ending index of the slice. 
		 * @see Array#slice
		 */
		public static function sliceAction(action:String, startIndex:uint, endIndex:uint = uint.MAX_VALUE):String {
			action = sanitizeFragment(action);
			var actionSplit:Array = action.split(separator);
			return actionSplit.slice(startIndex, endIndex).join(separator);
		}
		
		/**
		 * Sanitizes the fragment so:
		 * 1. It doesn't start with the separator.
		 * 2. It doesn't end with the separator.
		 */
		public static function sanitizeFragment(f:String):String {
			var separatorL:uint = separator.length;
			if (f.substr(0, separatorL) == separator) f = f.substr(separatorL, f.length);
			if (f.substr(-separatorL, separatorL) == separator) f = f.substring(0, f.length - separatorL);
			return f;
		}
	}
}

import com.nbilyk.managers.IPrettyHistoryManagerClient;

class SingletonEnforcer {}

class InitialSeparator implements IPrettyHistoryManagerClient {
	public function getParamCount():uint { return 1; }
	public function getClientDepth():uint { return 0; }
	public function loadState(args:Array):void {}
	public function saveState():Array { return [""]; }
}