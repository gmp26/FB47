package org.maths.nrich.flows.interfaces
{
	import mx.core.IUIComponent;
	
	import org.maths.Expression;

	public interface IDropPad extends IUIComponent
	{
/*
		function get text():String;
		function set text(s:String):void;
*/
		function get expression():Expression;
		function set expression(expr:Expression):void
		function dragOver():void;
		function dragOut():void;
	}
}