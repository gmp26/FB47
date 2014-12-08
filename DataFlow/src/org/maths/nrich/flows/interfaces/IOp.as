package org.maths.nrich.flows.interfaces
{
	public interface IOp
	{
		/**
		 * 
		 * @return the operator in text 
		 * 
		 */
		function toString():String;
		
		/**
		 * Sets the text needed to represent the operator 
		 * @param s
		 * 
		 */
		function set opText(s:String):void;
		
	}
}