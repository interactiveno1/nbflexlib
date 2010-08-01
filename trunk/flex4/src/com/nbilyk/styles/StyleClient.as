package com.nbilyk.styles {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.IInvalidating;
	import mx.core.Singleton;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IStyleClient;
	import mx.styles.IStyleManager2;
	import mx.styles.StyleProtoChain;
	import mx.utils.NameUtil;

	public class StyleClient extends EventDispatcher implements IStyleClient {

		private var styleManager:IStyleManager2;
		
		public function StyleClient() {
			styleManager = Singleton.getInstance("mx.styles::IStyleManager2") as IStyleManager2;
			regenerateStyleCache(true);
		}
		
		[Bindable(style="true")]
		/**
		 *  Gets a style property that has been set anywhere in this
		 *  component's style lookup chain.
		 *
		 *  <p>This same method is used to get any kind of style property,
		 *  so the value returned can be a Boolean, String, Number, int,
		 *  uint (for an RGB color), Class (for a skin), or any kind of object.
		 *  Therefore the return type is simply specified as ~~.</p>
		 *
		 *  <p>If you are getting a particular style property, you 
		 *  know its type and often want to store the result in a
		 *  variable of that type.
		 *  No casting from ~~ to that type is necessary.</p>
		 *
		 *  <p>
		 *  <code>
		 *  var backgroundColor:uint = getStyle("backgroundColor");
		 *  </code>
		 *  </p>
		 *
		 *  <p>If the style property has not been set anywhere in the
		 *  style lookup chain, the value returned by <code>getStyle()</code>
		 *  is <code>undefined</code>.
		 *  Note that <code>undefined</code> is a special value that is
		 *  not the same as <code>false</code>, <code>""</code>,
		 *  <code>NaN</code>, <code>0</code>, or <code>null</code>.
		 *  No valid style value is ever <code>undefined</code>.
		 *  You can use the method
		 *  <code>IStyleManager2.isValidStyleValue()</code>
		 *  to test whether the value was set.</p>
		 *
		 *  @param styleProp Name of the style property.
		 *
		 *  @return Style value.
		 */
		public function getStyle(styleProp:String):* {
			return styleManager.inheritingStyles[styleProp] ? _inheritingStyles[styleProp] : _nonInheritingStyles[styleProp];
		}

		/**
		 *  Sets a style property on this component instance.
		 *
		 *  <p>This can override a style that was set globally.</p>
		 *
		 *  <p>Calling the <code>setStyle()</code> method can result in decreased performance.
		 *  Use it only when necessary.</p>
		 *
		 *  @param styleProp Name of the style property.
		 *
		 *  @param newValue New value for the style.
		 */
		public function setStyle(styleProp:String, newValue:*):void {
			StyleProtoChain.setStyle(this, styleProp, newValue);
		}

		/**
		 *  Deletes a style property from this component instance.
		 *
		 *  <p>This does not necessarily cause the <code>getStyle()</code> method
		 *  to return <code>undefined</code>.</p>
		 *
		 *  @param styleProp The name of the style property.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function clearStyle(styleProp:String):void {
			setStyle(styleProp, undefined);
		}
		

		/**
		 *  The name of this instance's class, such as <code>"Button"</code>.
		 *  This string does not include the package name.
		 */
		public function get className():String {
			return NameUtil.getUnqualifiedClassName(this);
		}

		/**
		 *  @private
		 *  Storage for the inheritingStyles property.
		 */
		private var _inheritingStyles:Object = StyleProtoChain.STYLE_UNINITIALIZED;

		[Inspectable(environment="none")]

		/**
		 *  The beginning of this component's chain of inheriting styles.
		 *  The <code>getStyle()</code> method simply accesses
		 *  <code>inheritingStyles[styleName]</code> to search the entire
		 *  prototype-linked chain.
		 *  This object is set up by <code>initProtoChain()</code>.
		 *  Developers typically never need to access this property directly.
		 */
		public function get inheritingStyles():Object {
			return _inheritingStyles;
		}

		/**
		 *  @private
		 */
		public function set inheritingStyles(value:Object):void {
			_inheritingStyles = value;
		}

		/**
		 *  @private
		 *  Storage for the nonInheritingStyles property.
		 */
		private var _nonInheritingStyles:Object = StyleProtoChain.STYLE_UNINITIALIZED;

		[Inspectable(environment="none")]

		/**
		 *  The beginning of this component's chain of non-inheriting styles.
		 *  The <code>getStyle()</code> method simply accesses
		 *  <code>nonInheritingStyles[styleName]</code> to search the entire
		 *  prototype-linked chain.
		 *  This object is set up by <code>initProtoChain()</code>.
		 *  Developers typically never need to access this property directly.
		 */
		public function get nonInheritingStyles():Object {
			return _nonInheritingStyles;
		}

		/**
		 *  @private
		 */
		public function set nonInheritingStyles(value:Object):void {
			_nonInheritingStyles = value;
		}

		/**
		 *  @private
		 *  Storage for the styleDeclaration property.
		 */
		private var _styleDeclaration:CSSStyleDeclaration;

		[Inspectable(environment="none")]

		/**
		 *  Storage for the inline inheriting styles on this object.
		 *  This CSSStyleDeclaration is created the first time that
		 *  the <code>setStyle()</code> method
		 *  is called on this component to set an inheriting style.
		 *  Developers typically never need to access this property directly.
		 */
		public function get styleDeclaration():CSSStyleDeclaration {
			return _styleDeclaration;
		}

		/**
		 *  @private
		 */
		public function set styleDeclaration(value:CSSStyleDeclaration):void {
			_styleDeclaration = value;
		}

		/**
		 *  Finds the type selectors for this UIComponent instance.
		 *  The algorithm walks up the superclass chain.
		 *  For example, suppose that class MyButton extends Button.
		 *  A MyButton instance first looks for a MyButton type selector
		 *  then, it looks for a Button type selector.
		 *  then, it looks for a UIComponent type selector.
		 *  (The superclass chain is considered to stop at UIComponent, not Object.)
		 *
		 *  @return An Array of type selectors for this StyleClient instance.
		 */
		public function getClassStyleDeclarations():Array {
			return StyleProtoChain.getClassStyleDeclarations(this);
		}

		/**
		 * We do not have children, so this does nothing. Override if this is not the case.
		 */
		public function notifyStyleChangeInChildren(styleProp:String, recursive:Boolean):void {
			// no-op
		}

		/**
		 *  Builds or rebuilds the CSS style cache for this component
		 *  and, if the <code>recursive</code> parameter is <code>true</code>,
		 *  for all descendants of this component as well.
		 *
		 *  <p>The Flex framework calls this method in the following
		 *  situations:</p>
		 *
		 *  <ul>
		 *    <li>When you add a UIComponent to a parent using the
		 *    <code>addChild()</code> or <code>addChildAt()</code> methods.</li>
		 *    <li>When you change the <code>styleName</code> property
		 *    of a UIComponent.</li>
		 *    <li>When you set a style in a CSS selector using the
		 *    <code>setStyle()</code> method of CSSStyleDeclaration.</li>
		 *  </ul>
		 *
		 *  <p>Building the style cache is a computation-intensive operation,
		 *  so avoid changing <code>styleName</code> or
		 *  setting selector styles unnecessarily.</p>
		 *
		 *  <p>This method is not called when you set an instance style
		 *  by calling the <code>setStyle()</code> method of UIComponent.
		 *  Setting an instance style is a relatively fast operation
		 *  compared with setting a selector style.</p>
		 *
		 *  <p>You do not need to call or override this method.</p>
		 *
		 *  @param recursive Recursively regenerates the style cache for
		 *  all children of this component.
		 */
		public function regenerateStyleCache(recursive:Boolean):void {
			// Regenerate the proto chain for this object
			StyleProtoChain.initProtoChain(this);
		}

		public function registerEffects(effects:Array):void {
			// Does nothing
		}

		/**
		 *  @private
		 *  Storage for the styleName property.
		 */
		private var _styleName:Object /* String, CSSStyleDeclaration, or UIComponent */;
		
		[Inspectable(category="General")]

		/**
		 *  The class style used by this component. This can be a String, CSSStyleDeclaration
		 *  or an IStyleClient.
		 *
		 *  <p>If this is a String, it is the name of one or more whitespace delimited class
		 *  declarations in an <code>&lt;fx:Style&gt;</code> tag or CSS file. You do not include the period
		 *  in the <code>styleName</code>. For example, if you have a class style named <code>".bigText"</code>,
		 *  set the <code>styleName</code> property to <code>"bigText"</code> (no period).</p>
		 *
		 *  <p>If this is an IStyleClient (typically a UIComponent), all styles in the
		 *  <code>styleName</code> object are used by this component.</p>
		 *
		 *  @default null
		 *
		 */
		public function get styleName():Object /* String, CSSStyleDeclaration, or UIComponent */ {
			return _styleName;
		}

		/**
		 *  @private
		 */
		public function set styleName(value:Object /* String, CSSStyleDeclaration, or UIComponent */):void {
			if (_styleName === value)
				return;

			_styleName = value;

			// If inheritingStyles is undefined, then this object is being
			// initialized and we haven't yet generated the proto chain.
			// To avoid redundant work, don't bother to create
			// the proto chain here.
			if (inheritingStyles == StyleProtoChain.STYLE_UNINITIALIZED)
				return;

			regenerateStyleCache(true);

			styleChanged("styleName");

			notifyStyleChangeInChildren("styleName", true);
		}

		/**
		 *  Detects changes to style properties. When any style property is set,
		 *  Flex calls the <code>styleChanged()</code> method,
		 *  passing to it the name of the style being set.
		 *
		 *  <p>This is an advanced method that you might override
		 *  when creating a subclass of UIComponent. When you create a custom component,
		 *  you can override the <code>styleChanged()</code> method
		 *  to check the style name passed to it, and handle the change accordingly.
		 *  This lets you override the default behavior of an existing style,
		 *  or add your own custom style properties.</p>
		 *
		 *  <p>If you handle the style property, your override of
		 *  the <code>styleChanged()</code> method should call the
		 *  <code>invalidateDisplayList()</code> method to cause Flex to execute
		 *  the component's <code>updateDisplayList()</code> method at the next screen update.</p>
		 *
		 *  @param styleProp The name of the style property, or null if all styles for this
		 *  component have changed.
		 */
		public function styleChanged(styleProp:String):void {
			if (this is IInvalidating) StyleProtoChain.styleChanged(IInvalidating(this), styleProp);

			if (styleProp && (styleProp != "styleName")) {
				if (hasEventListener(styleProp + "Changed"))
					dispatchEvent(new Event(styleProp + "Changed"));
			} else {
				if (hasEventListener("allStylesChanged"))
					dispatchEvent(new Event("allStylesChanged"));
			}
		}
		
	}
}