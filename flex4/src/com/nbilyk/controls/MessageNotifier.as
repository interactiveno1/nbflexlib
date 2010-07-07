/**
 * Copyright (c) 2009 Nicholas Bilyk
 */

package com.nbilyk.controls {
	import com.nbilyk.utils.EventQueue;
	import com.nbilyk.utils.QueuedEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import mx.containers.HBox;
	import mx.controls.Text;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.effects.easing.Sine;
	import mx.styles.CSSStyleDeclaration;

	[Style(name="paddingLeft",type="Number")]
	[Style(name="paddingTop",type="Number")]
	[Style(name="paddingRight",type="Number")]
	[Style(name="messageStyleName",type="String")]
	[Style(name="errorMessageStyleName",type="String")]
	public class MessageNotifier extends CSSStyleDeclaration {
		private var eventQueue:EventQueue = new EventQueue();

		private var componentHideTimeout:int;
		[ArrayElementType("flash.filters.BitmapFilter")]
		public var messageFilters:Array = [];
		
		/**
		 * The duration of the show transition in milliseconds.
		 */
		public var tweenDuration:Number = 400;
		
		/**
		 * The easing function of the tween.  Will be reversed on ease out.
		 * This method must have the following signature:
		 *   @param t Specifies time.
		 *   @param b Specifies the initial position of a component.
		 *   @param c Specifies the total change in position of the component.
		 *   @param d Specifies the duration of the effect, in milliseconds.
		 *   @return Number corresponding to the position of the component.
		 */  
		public var tweenEase:Function = Sine.easeIn;
		
		private var startTime:Number;
		private var isReversed:Boolean;

		public function MessageNotifier() {
			super();
		}

		/**
		 * Adds a message to be queued for showing.
		 * @param message The message text to show.
		 * @param isError If true, errorMessageStyleName is used, if false, messageStyleName is.
		 * @param duration The duration, in milliseconds to show the message. 
		 * If this is -1, it will be derived based on the number of characters for the message.
		 */
		public function showMessage(message:String, isError:Boolean = false, duration:int = -1, priority:int = 0, clickToClose:Boolean = true):void {
			if (!message) return;
			var text:Text = new Text();
			text.htmlText = message;
			text.percentWidth = 100;
			var hBox:HBox = new HBox();
			hBox.addChild(text);
			hBox.styleName = (isError) ? getStyle("errorMessageStyleName") : getStyle("messageStyleName");
			if (clickToClose) {
				text.selectable = false;
				text.useHandCursor = true;
				text.buttonMode = true;
				hBox.mouseChildren = false;
				hBox.useHandCursor = true;
				hBox.buttonMode = true;
				hBox.toolTip = "Click to close";
				hBox.addEventListener(MouseEvent.CLICK, componentClickHandler, false, 0, true);
			}
			hBox.filters = messageFilters;

			if (duration == -1) duration = Math.min(15000, Math.max(message.length * 30 + 2000, 1000));
			showComponent(hBox, duration, priority);
		}
		
		/**
		 * Adds a component to the queue to be shown.  If you have a text message, use <code>showMessage</code>.
		 */
		public function showComponent(component:UIComponent, duration:int = 4500, priority:int = 0):void {
			component.includeInLayout = false;
			component.visible = false;
			eventQueue.addEvent(new QueuedEvent(doShowComponent, [ component, duration ], priority));
		}

		private function doShowComponent(component:UIComponent, duration:int):void {
			if (!component.parent) app.addChild(component);

			if (!component.initialized) {
				app.callLater(doShowComponent, [ component, duration ]);
				return;
			}
			startTime = getTimer();
			isReversed = false;
			refreshComponent(component);
			
			component.addEventListener(Event.ENTER_FRAME, componentEnterFrameHandler, false, 0, true);
			componentHideTimeout = setTimeout(hideComponent, tweenDuration + duration, component);
		}

		private function componentEnterFrameHandler(event:Event):void {
			refreshComponent(UIComponent(event.currentTarget));
		}

		protected function refreshComponent(component:UIComponent):void {
			if (!component.visible && component.height) component.visible = true;
			var p:Number = (getTimer() - startTime) / tweenDuration;
			if (isReversed) p = 1 - p;
			p = Math.max(0, Math.min(1, p));
			p = Sine.easeIn(p, 0, 1, 1);
			
			var startY:Number = -component.height;
			var endY:Number = getStyle("paddingTop") + app.verticalScrollPosition;
			component.x = getStyle("paddingLeft");
			component.y = (endY - startY) * p + startY;
			component.setActualSize(app.width - getStyle("paddingLeft") - getStyle("paddingRight"), component.getExplicitOrMeasuredHeight());
		}

		private function componentClickHandler(event:MouseEvent):void {
			hideComponent(UIComponent(event.currentTarget));
		}

		private function hideComponent(component:UIComponent):void {
			clearTimeout(componentHideTimeout);
			startTime = getTimer();
			isReversed = true;
			setTimeout(hideComponentComplete, tweenDuration, component);
		}
		
		private function hideComponentComplete(component:UIComponent):void {
			component.removeEventListener(Event.ENTER_FRAME, componentEnterFrameHandler);
			component.parent.removeChild(component);
			eventQueue.completeEvent();
		}

		//--------------------
		// Helper functions
		//--------------------

		private function get app():Object {
			return FlexGlobals.topLevelApplication;
		}

	}
}