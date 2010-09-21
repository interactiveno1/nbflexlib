package com.nbilyk.utils {
	
	import mx.core.IFactory;
	
	public class FunctionFactory implements IFactory {
		
		/**
		 * The arguments to pass to [func].
		 */
		public var args:Array;
		
		/**
		 * The function to call when the factory is invoked. (Required)
		 */
		public var func:Function;
		
		public function FunctionFactory(funcVal:Function = null, argsVal:Array = null) {
			func = funcVal;
			args = argsVal;
		}
		
		public function newInstance():* {
			if (func == null) return null;
			return func.apply(null, args);
		}
	}
}