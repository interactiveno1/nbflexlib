package com.nbilyk.sharedobject {
	import com.nbilyk.utils.ObjectUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	import flash.net.registerClassAlias;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	[Event(name="saveSuccess", type="flash.event.Event")]
	[Event(name="saveFail", type="flash.event.Event")]
	public class AbstractPersistantData extends EventDispatcher {
		public static const SAVE_SUCCESS:String = "saveSuccess";
		public static const SAVE_FAIL:String = "saveFail";
		
		private var _cookieName:String;
		[ArrayElementType("SharedObject")]
		private static var sharedObjects:Object = new Object();
		
		public function AbstractPersistantData(cookieName:String, autoFetch:Boolean = false) {
			var className:String = getQualifiedClassName(this); 
			if (Class(getDefinitionByName(className)) == AbstractPersistantData) throw new Error('AbstractPersistantData must be extended');
			if (!cookieName) throw new ArgumentError("Argument cookieName is required.");
			
			_cookieName = cookieName;
			if (autoFetch) fetch();
		}
		public function get cookieName():String {
			return _cookieName;
		}
		protected function get so():SharedObject {
			if (sharedObjects[cookieName]) return sharedObjects[cookieName];
			var newSharedObject:SharedObject = SharedObject.getLocal(cookieName);
			newSharedObject.objectEncoding = ObjectEncoding.AMF3;
			sharedObjects[cookieName] = newSharedObject;
			return newSharedObject;
		}
		public function fetch():void {
			var className:String = getQualifiedClassName(this);
			var classNameParts:Array = className.split("::");
			var classAliasName:String = classNameParts.pop() + "Alias";
			registerClassAlias(classAliasName, Class(getDefinitionByName(className)));
			
			if (so.data.data) {
				ObjectUtils.mergeObjects(this, so.data.data);
			} 
		}
		public function clear():void {
			so.clear();
		}
		public function save():void {
			clear();
			so.data.data = this;
			
			var flushStatus:String = null;
			try {
				flushStatus = so.flush(so.size);
			} catch (error:Error) {
				dispatchEvent(new Event(SAVE_FAIL));
			}
			if (flushStatus != null) {
				switch (flushStatus) {
					case SharedObjectFlushStatus.PENDING:
						so.addEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
						break;
					case SharedObjectFlushStatus.FLUSHED:
						dispatchEvent(new Event(SAVE_SUCCESS));
						break;
				}
			}
		}
		private function onFlushStatus(event:NetStatusEvent):void {
			so.removeEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
			switch (event.info.code) {
				case "SharedObject.Flush.Success":
					dispatchEvent(new Event(SAVE_SUCCESS));
					break;
				case "SharedObject.Flush.Failed":
					dispatchEvent(new Event(SAVE_FAIL));
					break;
			}
		}
	}
}