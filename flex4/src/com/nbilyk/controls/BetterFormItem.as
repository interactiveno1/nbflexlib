/**
 *  Written by Nicholas Bilyk
 *  http://www.nbilyk.com
 *  This class lets you do a few things that the native FormItem cannot.
 *  - HTML labels
 *  - Multiline labels
 *  - Selectable labels
 *  - Max width labels
 */

package com.nbilyk.controls {
	import mx.containers.FormItem;
	import mx.controls.Text;

	[Style(name="labelStyleName", type="String")]
	[Style(name="defaultSelectable", type="Boolean")]
	public class BetterFormItem extends FormItem {
		public var maxLabelWidth:Number;
		public var text:Text;
		[Inspectable]
		public var multiline:Boolean = false;
		private var _selectable:Boolean = true;
		private var _labelToolTip:String;
		private var toolTipExplicitlySet:Boolean;
		private var selectableExplicitlySet:Boolean;

		public function BetterFormItem() {
			super();
		}

		override public function styleChanged(styleProp:String):void {
			super.styleChanged(styleProp);
			var allStyles:Boolean = styleProp == null || styleProp == "styleName";

			if (allStyles || styleProp == "labelStyleName") {
				if (text) {
					text.styleName = getStyle("labelStyleName");
				}
			}
			if (allStyles || styleProp == "defaultSelectable") {
				if (!selectableExplicitlySet) {
					_selectable = getStyle("defaultSelectable");
					if (itemLabel) itemLabel.selectable = _selectable;
				}
			}
		}

		override protected function createChildren():void {
			super.createChildren();
			if (maxLabelWidth)
				itemLabel.maxWidth = maxLabelWidth;
			if (multiline) {
				itemLabel.visible = false;
				text = new Text();

				text.setStyle("textAlign", "right");
				text.selectable = selectable;

				text.styleName = getStyle("labelStyleName");
				rawChildren.addChild(text);
			} else {
				itemLabel.selectable = selectable;
			}
		}

		override protected function commitProperties():void {
			super.commitProperties();
			if (multiline) {
				text.htmlText = itemLabel.text;
			}
			if (toolTipExplicitlySet) {
				toolTipExplicitlySet = false;
				text.toolTip = labelToolTip;
			}
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (multiline) {
				text.explicitWidth = itemLabel.width;
				text.validateNow();
				text.setActualSize(itemLabel.width, text.measuredHeight + 3);
				text.validateSize();
			}
		}

		override protected function measure():void {
			super.measure();
			if (multiline) {
				measuredMinHeight = Math.max(measuredMinHeight, text.measuredMinHeight);
				measuredHeight = Math.max(measuredHeight, text.measuredHeight);
			}
		}

		public function get labelToolTip():String {
			return _labelToolTip;
		}

		public function set labelToolTip(value:String):void {
			_labelToolTip = value;
			toolTipExplicitlySet = true;
			invalidateProperties();
		}

		[Inspectable]
		public function get selectable():Boolean {
			return _selectable;
		}

		public function set selectable(value:Boolean):void {
			_selectable = value;
			selectableExplicitlySet = true;
			if (itemLabel) itemLabel.selectable = value;
		}

	}
}