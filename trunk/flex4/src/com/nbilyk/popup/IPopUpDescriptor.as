package com.nbilyk.popup {
	import mx.core.UIComponent;

	public interface IPopUpDescriptor {
		function createPopUp():UIComponent;
		
		/**
		 * close is called when the pop-up is closed.
		 * Note that calling this will not close the pop-up.  
		 * @see NPopUp#closePopUp
		 */
		function close():void;
		
		/**
		 * The parent to which this PopUp will be added.
		 */
		function get parent():UIComponent;
		
		/**
		 * If true, the container is modal which means that
		 * the user will not be able to interact with other popups until the window
		 * is removed.
		 * This also defines if clicking outside of the container closes the PopUp.
		 */
		function get modal():Boolean;
		
		/**
		 * If true, pressing escape will close the PopUp.
		 */
		function get escapeCloses():Boolean;
			
		/**
		 * If true, clicking outside of the PopUp area closes the PopUp.
		 */
		function get clickOutsideCloses():Boolean;
		
		/**
		 * If true, the container will be sized and positioned automatically on parent resizes.
		 */
		function get autoLayout():Boolean;
		
		/**
		 * The method that positions and sizes the container within its parent.
		 * It should have the signature:
		 * 	layoutFunction(popUpDescriptor:PopUpDescriptor):void
		 */
		function get layoutFunction():Function;
		
	}
}