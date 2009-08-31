/**
 * Copyright (c) 2009 Nicholas Bilyk
 */

package com.nbilyk.display {
	import com.nbilyk.utils.EventQueue;
	import com.nbilyk.utils.QueuedEvent;
	
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import mx.containers.HBox;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.effects.IEffect;
	import mx.effects.Move;
	import mx.effects.easing.Sine;
	import mx.events.EffectEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	[Style(name="messageStyleName", type="String")]
	[Style(name="errorMessageStyleName", type="String")]
	[Style(name="paddingLeft", type="Number")]
	[Style(name="paddingTop", type="Number")]
	[Style(name="paddingRight", type="Number")]
	[Style(name="paddingBottom", type="Number")]
	
	[Effect(name="showEffect", event="show")]
	[Effect(name="hideEffect", event="hide")]
	public class MessageNotifier extends CSSComponent {
		public static const TOP:uint = 0;
		public static const BOTTOM:uint = 0;
		
		private var eventQueue:EventQueue = new EventQueue();
		private var location:uint;
		
		private var paddingLeft:Number;
		private var paddingTop:Number;
		private var paddingRight:Number;
		private var paddingBottom:Number;
		
		private var defaultShowEffect:Move;
		private var defaultHideEffect:Move;
		
		public function MessageNotifier(locationVal:uint = TOP) {
			super();
			location = locationVal;
			
			// Default styles and effects
			defaultShowEffect = new Move();
			defaultShowEffect.duration = 400;
			defaultShowEffect.easingFunction = Sine.easeOut;
			
			defaultHideEffect = new Move();
			defaultHideEffect.duration = 400;
			defaultHideEffect.easingFunction = Sine.easeIn;
			
			var messageNotifierCss:CSSStyleDeclaration = new CSSStyleDeclaration("MessageNotifier");
			if (messageNotifierCss.defaultFactory == null) {
				messageNotifierCss.defaultFactory = function():void {
					this.showEffect = defaultShowEffect;
					this.hideEffect = defaultHideEffect;
					this.paddingLeft = 10;
					this.paddingTop = 10;
					this.paddingRight = 10;
					this.paddingBottom = 10;
					this.messageStyleName = "messageStyle82";
					this.errorMessageStyleName = "errorMessageStyle82";
				}
				StyleManager.setStyleDeclaration("MessageNotifier", messageNotifierCss, true);
				
				var messageCss:CSSStyleDeclaration = new CSSStyleDeclaration(".messageStyle82");
				messageCss.defaultFactory = function():void {
					this.paddingLeft = 3;
					this.paddingTop = 3;
					this.paddingRight = 3;
					this.paddingBottom = 3;
					this.borderStyle = "solid";
					this.borderThickness = 2;
					this.cornerRadius = 8;
					this.backgroundColor = 0xFFFFFF;
					this.fontWeight = "bold";
				}
				StyleManager.setStyleDeclaration(".messageStyle82", messageCss, true);
				
				var errorMessageCss:CSSStyleDeclaration = new CSSStyleDeclaration(".errorMessageStyle82");
				errorMessageCss.defaultFactory = function():void {
					this.paddingLeft = 3;
					this.paddingTop = 3;
					this.paddingRight = 3;
					this.paddingBottom = 3;
					this.borderStyle = "solid";
					this.borderThickness = 2;
					this.cornerRadius = 8;
					this.backgroundColor = 0xFFFFFF;
					this.fontWeight = "bold";
					this.color = 0xFF0000;
				}
				StyleManager.setStyleDeclaration(".errorMessageStyle82", errorMessageCss, true);
			}
		}
		
		public function showMessage(message:String, isError:Boolean = false, duration:int = -1, priority:int = 0):void {
			paddingLeft = Number(getStyle("paddingLeft"));
			paddingTop = Number(getStyle("paddingTop"));
			paddingRight = Number(getStyle("paddingRight"));
			paddingBottom = Number(getStyle("paddingBottom"));
			
			var text:CSSText = new CSSText();
			text.text = message;
			text.percentWidth = 100;
			var hBox:HBox = new HBox();
			hBox.addChild(text);
			hBox.styleName = (isError) ? getStyle("errorMessageStyleName") : getStyle("messageStyleName");
			hBox.includeInLayout = false;
			hBox.setStyle("left", paddingLeft);
			hBox.setStyle("right", paddingRight);
			
			if (duration == -1) duration = Math.min(15000, Math.max(message.length / 30 * 1000, 4500));
			showComponent(hBox, duration, priority);
		}
		public function showComponent(component:UIComponent, duration:int = 4500, priority:int = 0):void {
			eventQueue.addEvent(new QueuedEvent(doShowComponent, [component, duration], priority));
		}
		private function doShowComponent(component:UIComponent, duration:int):void {
			if (!component.parent) app.addChild(component);
			
			if (!component.initialized) {
				app.callLater(doShowComponent, [component, duration]);
				return;
			}
			refreshComponent(component);
			
			var showEffect:IEffect = IEffect(getStyle("showEffect"));
			if (showEffect) {
				showEffect.addEventListener(EffectEvent.EFFECT_END, showEffectEndHandler);
				showEffect.play([component]);
				setTimeout(showComponentComplete, showEffect.duration + duration, component);
			} else {
				component.addEventListener(Event.ENTER_FRAME, componentEnterFrameHandler);
				setTimeout(showComponentComplete, duration, component);
			}
		}
		private function showEffectEndHandler(event:EffectEvent):void {
			var showEffect:IEffect = IEffect(event.currentTarget);
			showEffect.removeEventListener(EffectEvent.EFFECT_END, showEffectEndHandler);
			var component:UIComponent = UIComponent(event.effectInstance.target);
			component.addEventListener(Event.ENTER_FRAME, componentEnterFrameHandler);
		}
		private function componentEnterFrameHandler(event:Event):void {
			refreshComponent(UIComponent(event.currentTarget));
		}
		private function refreshComponent(component:UIComponent):void {
			if (location == TOP) {
				var topY:Number = paddingTop + app.verticalScrollPosition;
				defaultShowEffect.yTo = topY;
				defaultShowEffect.yFrom = topY - component.measuredHeight - paddingTop;
				component.y = topY;
			} else {
				var bottomY:Number = app.height + app.verticalScrollPosition - component.measuredHeight - paddingBottom;
				defaultShowEffect.yTo = bottomY;
				defaultShowEffect.yFrom = bottomY + component.measuredHeight + paddingBottom;
				component.y = bottomY;
			}
			defaultHideEffect.yTo = defaultShowEffect.yFrom;
			defaultHideEffect.yFrom = defaultShowEffect.yTo;
		}
		
		private function showComponentComplete(component:UIComponent):void {
			component.removeEventListener(Event.ENTER_FRAME, componentEnterFrameHandler);
			var hideEffect:IEffect = IEffect(getStyle("hideEffect"));
			if (hideEffect) {
				hideEffect.addEventListener(EffectEvent.EFFECT_END, hideCompleteHandler);
				hideEffect.play([component]);
			} else {
				component.parent.removeChild(component);
				eventQueue.completeEvent();
			}
		}
		private function hideCompleteHandler(event:EffectEvent):void {
			var hideEffect:IEffect = IEffect(event.currentTarget);
			hideEffect.removeEventListener(EffectEvent.EFFECT_END, hideCompleteHandler);
			var component:UIComponent = UIComponent(event.effectInstance.target);
			if (component.parent) component.parent.removeChild(component);
			eventQueue.completeEvent();
		}
		
		//--------------------
		// Helper functions
		//--------------------
		
		private function get app():Application {
			return Application(Application.application);
		}

	}
}