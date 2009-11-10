package com.nbilyk.effects.bitmaptransitions {
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class BitmapWipeTransition extends BitmapTransition {
		public static const LEFT:String = "left";
		public static const UP:String = "up";
		public static const RIGHT:String = "right";
		public static const DOWN:String = "down";
		
		private var _direction:String;
		private var startX:Number;
		private var startY:Number;
		
		public function BitmapWipeTransition(targetVal:DisplayObject, directionVal:String = LEFT) {
			super(targetVal);
			direction = directionVal;
		}
		
		/**
		 * The direction the wipe transition will move.  So 'left' will cause the transition to wipe from right to left.  
		 */
		public function get direction():String {
			return _direction;
		}
		public function set direction(value:String):void {
			_direction = value;
		}
		
		override protected function tweenStart():void {
			if (!beforeSnapshot || !afterSnapshot) return;
			var mask:DisplayObject = createMask();
			
			switch (direction) {
				case (UP) :
					startX = target.x;
					startY = target.y + target.height;
					break;
				case (RIGHT) :
					startX = target.x - target.width;
					startY = target.y;
					break;
				case (DOWN) :
					startX = target.x;
					startY = target.y - target.height;
					break;
				default :
					startX = target.x + target.width;
					startY = target.y;
				
			}
			
			
			mask.x = startX;
			mask.y = startY;
			
			targetParent.addChild(mask);
			afterSnapshot.mask = mask;
		}
		override protected function tweenUpdate(value:Number):void {
			if (!afterSnapshot) return;
			var endX:Number = target.x;
			var endY:Number = target.y;
			
			afterSnapshot.mask.x = value * (endX - startX) + startX;
			afterSnapshot.mask.y = value * (endY - startY) + startY;
		}
		
		protected function createMask():DisplayObject {
			var mask:Sprite = new Sprite();
			var g:Graphics = mask.graphics;
			g.beginFill(0, 1);
			g.drawRect(0, 0, target.width, target.height);
			g.endFill();
			mask.cacheAsBitmap = true;
			return mask;
		}
	}
}