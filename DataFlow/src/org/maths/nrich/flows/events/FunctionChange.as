package org.maths.nrich.flows.events
{
	import flash.events.Event;
	
	import org.maths.Expression;
	
	public class FunctionChange extends Event
	{
		
		public static const NEW_NAME:String = "newFunctionName";
		public static const NEW_VARS:String = "newVarNames";
		public static const NEW_EXPRESSION:String = "newExpression";
		
		public var name:String;
		public var vars:String;
		public var expr:Expression;
		
		public function FunctionChange(type:String, name:String=null, vars:String=null, expr:Expression=null)
		{
			super(type);
			this.name = name;
			this.vars = vars;
			this.expr = expr;
		}
	}
}