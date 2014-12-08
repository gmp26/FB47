package org.maths.nrich.flows.events
{
	import flash.events.Event;
	
	public class VariableChangeEvent extends Event
	{
		public static const RENAME:String = "rename"
		
		public var oldName:String;
		public var newName:String;
			
		public function VariableChangeEvent(type:String, oldName:String, newName:String)
		{
			this.oldName = oldName;
			this.newName = newName;
			super(type, false, false);
		}
	}
}