package com.nbilyk.formatters {

	import com.nbilyk.utils.DateUtils;
	
	import mx.core.mx_internal;
	import mx.formatters.DateBase;
	import mx.formatters.DateFormatter;
	import mx.formatters.Formatter;
	import mx.formatters.StringFormatter;
	import mx.managers.ISystemManager;
	import mx.managers.SystemManager;

	[ResourceBundle("nbflexlib")]
	public class NDateTimeFormatter extends Formatter {

		private static const VALID_PATTERN_CHARS:String = "Y,M,D,A,E,H,J,K,L,N,S,Q";

		private var _dateFormat:String;
		private var _timeFormat:String;
		private var dateFormatOverride:String;
		private var timeFormatOverride:String;
		protected var dateStringFormatter:StringFormatter;
		protected var timeStringFormatter:StringFormatter;
		
		public function NDateTimeFormatter() {
			super();
		}

		override protected function resourcesChanged():void {
			super.resourcesChanged();
			dateFormat = dateFormatOverride;
			timeFormat = timeFormatOverride;
		}

		/**
		 * The date format will be used when the date value is before today.
		 */
		[Inspectable(category="General", defaultValue="null")]
		public function get dateFormat():String {
			return _dateFormat;
		}

		public function set dateFormat(value:String):void {
			dateFormatOverride = value;
			_dateFormat = value != null ? value : resourceManager.getString('nbflexlib', "dateFormat");
			dateStringFormatter = new StringFormatter(_dateFormat, VALID_PATTERN_CHARS, DateBase.mx_internal::extractTokenDate);
		}
		
		/**
		 * The time format will be used when the date value is today.
		 */
		[Inspectable(category="General", defaultValue="null")]
		public function get timeFormat():String {
			return _timeFormat;
		}
		
		public function set timeFormat(value:String):void {
			timeFormatOverride = value;
			_timeFormat = value != null ? value : resourceManager.getString("nbflexlib", "timeFormat");
			timeStringFormatter = new StringFormatter(_timeFormat, VALID_PATTERN_CHARS, DateBase.mx_internal::extractTokenDate);
		}

		override public function format(value:Object):String {
			var date:Date;
			if (error) error = null; // Reset any previous errors.

			if (!value || (value is String && value == "")) {
				error = defaultInvalidValueError;
				return "";
			}

			if (value is String) {
				date = DateFormatter.parseDateString(String(value));
			} else if (value is Date) {
				date = value as Date;
			}
			
			if (!date) {
				error = defaultInvalidValueError;
				return "";
			}
			
			if (DateUtils.isSameDay(new Date(), date)) {
				return timeStringFormatter.formatValue(date);
			} else {
				return dateStringFormatter.formatValue(date);
			}
		}
	}

}
