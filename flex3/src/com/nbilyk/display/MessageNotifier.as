/**
 * Copyright (c) 2009 Nicholas Bilyk
 */
package com.nbilyk.display {
	import com.nbilyk.utils.EventQueue;
	import com.nbilyk.utils.QueuedEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	
	import mx.containers.HBox;
	import mx.controls.Text;
	import mx.core.ApplicationGlobals;
	import mx.core.UIComponent;
	import mx.effects.easing.Sine;
	import mx.events.FlexEvent;

	[Style(name="paddingLeft",type="Number")]
	[Style(name="paddingTop",type="Number")]
	[Style(name="paddingRight",type="Number")]
	[Style(name="messageStyleName",type="String")]
	[Style(name="errorMessageStyleName",type="String")]
	public class MessageNotifier extends CSSComponent {
		private var eventQueue:EventQueue = new EventQueue();

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
		
		private var currentComponent:UIComponent;
		private var currentDuration:Number;

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

			if (duration == -1) duration = Math.min(15000, Math.max(message.length * 30 + 2000, 1000));
			showComponent(hBox, duration, priority);
		}
		
		/**
		 * Adds a component to the queue to be shown.  If you have a text message, use <code>showMessage</code>.
		 */
		public function showComponent(component:UIComponent, duration:int = 4500, priority:int = 0):void {
			component.visible = false;
			component.includeInLayout = false;
			
			eventQueue.addEvent(new QueuedEvent(doShowComponent, [ component, duration ], priority));
		}
		
		private function doShowComponent(component:UIComponent, duration:int):void {
			currentComponent = component;
			currentDuration = duration;
			
			if (!currentComponent.parent) app.addChild(currentComponent);
			if (currentComponent.initialized) componentCreationCompleteHandler();
			else currentComponent.addEventListener(FlexEvent.CREATION_COMPLETE, componentCreationCompleteHandler);
		}
		
		private function componentCreationCompleteHandler(event:FlexEvent = null):void {
			currentComponent.removeEventListener(FlexEvent.CREATION_COMPLETE, componentCreationCompleteHandler);
			startTime = getTimer();
			currentComponent.setActualSize(app.width - getStyle("paddingLeft") - getStyle("paddingRight"), currentComponent.getExplicitOrMeasuredHeight());
			currentComponent.validateSize(true);
			currentComponent.validateNow();
			currentComponent.addEventListener(FlexEvent.UPDATE_COMPLETE, componentUpdateCompleteHandler);
		}
		
		private function componentUpdateCompleteHandler(event:FlexEvent = null):void {
			currentComponent.removeEventListener(FlexEvent.UPDATE_COMPLETE, componentUpdateCompleteHandler);
			startTime = getTimer();
			isReversed = false;
			refreshCurrentComponent();
			currentComponent.visible = true;
			currentComponent.addEventListener(Event.ENTER_FRAME, componentEnterFrameHandler, false, 0, true);
		}

		private function componentEnterFrameHandler(event:Event):void {
			refreshCurrentComponent();
		}

		protected function refreshCurrentComponent():void {
			var elapsedTime:Number = getTimer() - startTime;
			var p:Number = elapsedTime / tweenDuration;
			if (isReversed) p = 1 - p;
			p = Math.max(0, Math.min(1, p));
			p = Sine.easeIn(p, 0, 1, 1);
			
			var startY:Number = -currentComponent.height;
			var endY:Number = getStyle("paddingTop") + app.verticalScrollPosition;
			currentComponent.move(getStyle("paddingLeft"), (endY - startY) * p + startY);
			currentComponent.setActualSize(app.width - getStyle("paddingLeft") - getStyle("paddingRight"), currentComponent.getExplicitOrMeasuredHeight());
			
			if (isReversed && p == 0) hideComponentComplete();
			if (!isReversed && elapsedTime > tweenDuration + currentDuration) hideCurrentComponent(); // We have shown the component long enough.
		}

		private function componentClickHandler(event:MouseEvent):void {
			hideCurrentComponent();
		}

		public function hideCurrentComponent():void {
			if (isReversed) return;
			startTime = getTimer();
			isReversed = true;
		}
		
		private function hideComponentComplete():void {
			currentComponent.removeEventListener(Event.ENTER_FRAME, componentEnterFrameHandler);
			if (currentComponent.parent) currentComponent.parent.removeChild(currentComponent);
			currentComponent = null;
			eventQueue.completeEvent();
		}

		//--------------------
		// Helper functions
		//--------------------

		private function get app():Object {
			return ApplicationGlobals.application;
		}

	}
}