package com.nbilyk.effects {
	import com.nbilyk.effects.effectclasses.BitmapFadeEffectInstance;
	
	public class BitmapFadeEffect extends BitmapEffect {
		public function BitmapFadeEffect() {
			super();
			instanceClass = BitmapFadeEffectInstance;
		}
	}
}