package com.nbilyk.effects.effectclasses {
	import com.nbilyk.effects.bitmaptransitions.BitmapTransition;
	
	import flash.display.DisplayObject;
	
	import mx.effects.Tween;
	import mx.effects.effectClasses.TweenEffectInstance;
	import mx.events.TweenEvent;

	/**
	 * This class is abstract.  Extend this class and override createTransition to return an instance of a BitmapTransition object.
	 */
	public class BitmapEffectInstance extends TweenEffectInstance {
		
		protected var bitmapTransition:BitmapTransition;
		
		public function BitmapEffectInstance(target:Object) {
			super(target);
			if (target is DisplayObject) { 
				bitmapTransition = createTransition(DisplayObject(target));
			}
		}
		
		/**
		 * This method is abstract.  Override this method to create a new BitmapTransition subclass instance.
		 */
		[Abstract]
		protected function createTransition(target:DisplayObject):BitmapTransition {
			throw new Error("createTransition is abstract, override this method.");
			return null;
		}

		override public function play():void {
			// Dispatch an effectStart event from the target.
			super.play();
			
			if (bitmapTransition) {
				bitmapTransition.beforeSnapshot = propertyChanges.start.beforeSnapshot;
				
				var newTween:Tween = bitmapTransition.start();
				newTween.addEventListener(TweenEvent.TWEEN_START, tweenEventHandler);
				newTween.addEventListener(TweenEvent.TWEEN_UPDATE, tweenEventHandler);
				newTween.addEventListener(TweenEvent.TWEEN_END, tweenEventHandler);

				// If the caller supplied their own easing equation, override the
				// one that's baked into Tween.
				if (easingFunction != null) newTween.easingFunction = easingFunction;
				newTween.duration = duration;
				tween = newTween;
			}
		}
		
		protected function tweenEventHandler(event:TweenEvent):void {
			dispatchEvent(event);
		}
	}
}