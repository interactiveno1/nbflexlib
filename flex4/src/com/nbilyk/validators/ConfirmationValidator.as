package com.nbilyk.validators {
	import mx.controls.TextInput;
	import mx.validators.ValidationResult;
	import mx.validators.Validator;

	public class ConfirmationValidator extends Validator {
		public var otherField:TextInput;
		public var noMatchError:String = "This field does not match.";
		
		public function ConfirmationValidator() {
			super();
			
			triggerEvent = "";
		}
		override protected function doValidation(value:Object):Array {
			var results:Array = super.doValidation(value);
			if (results.length > 0) return results;
			
			var val:String = value ? String(value) : "";
			if (val != otherField.text) {
				var vr:ValidationResult = new ValidationResult(true,"", "noMatch", noMatchError);
				results.push(vr);
			}
			return results;
	    }
	}
}