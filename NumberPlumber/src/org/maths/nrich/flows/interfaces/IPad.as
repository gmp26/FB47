package org.maths.nrich.flows.interfaces
{
	import flash.events.IEventDispatcher;
	
	import org.maths.Expression;

	public interface IPad extends IEventDispatcher
	{
		function get expression():Expression;
		function set expression(expr:Expression):void;
		function get showValues():int;
		function set showValues(value:int):void;

	}
}