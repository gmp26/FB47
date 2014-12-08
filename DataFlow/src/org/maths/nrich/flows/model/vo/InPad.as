package org.maths.nrich.flows.model.vo
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import org.maths.Expression;
	import org.maths.nrich.flows.interfaces.IPad;
	
	public class InPad extends EventDispatcher implements IPad
	{
		public static const CHANGE:String = "change";
		
		private var _expression:Expression;
		[Bindable]
		public function get expression():Expression
		{
			return _expression;
		}
		public function set expression(expr:Expression):void
		{
			if(_expression != expr) {
				_expression = expr;
/*				exprAsNumber = 0;
				if(expr) {
					var z:Complex =	expr.evaluate();
					if(z)
						exprAsNumber = z.x;
				}
*/
				dispatchEvent(new Event(CHANGE));
			}
		}
		
		[Bindable]
		public var exprAsNumber:Number = 0; 

		private var _showValues:int = 0;
		public function get showValues():int
		{
			return _showValues;
		}
		public function set showValues(value:int):void
		{
			_showValues = value;
			invalidPadSize = true;
		}
		
		[Bindable]
		public var minimum:Number = 0;

		[Bindable]
		public var maximum:Number = 10;
		
		public var invalidPadSize:Boolean = true;
		
		private var _padVariable:String = "x";
		
		[Bindable]
		public function get padVariable():String
		{
			return _padVariable;
		}
		public function set padVariable(s:String):void
		{
			_padVariable = s;
			invalidPadSize = true;
		}
				
	}
}