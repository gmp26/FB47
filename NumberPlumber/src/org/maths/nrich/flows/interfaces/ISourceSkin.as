package org.maths.nrich.flows.interfaces
{
	import org.maths.nrich.flows.components.Catcher;
	
	import spark.components.Group;
	import spark.components.Label;

	public interface ISourceSkin
	{
		function get padContainer():Group;
		
		function get catcher():Catcher;
		
		function get title():String;
		function set title(s:String):void;
		
		function get titleHolder():Label;
	}
}