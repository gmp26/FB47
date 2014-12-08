package org.maths.nrich.flows.components
{
	import mx.graphics.SolidColor;
	import mx.states.State;
	
	import spark.components.Label;
	import spark.components.SkinnableContainer;
	
	[SkinState('normal')]
	[SkinState('maximised')]
	public class TitledPanel extends SkinnableContainer
	{
		function TitledPanel() {
			// properties
			this.currentState = "normal";
			
			states = [
				new State ({
					name: "normal",
					overrides: [
					]
				})
				,
				new State ({
					name: "maximised",
					overrides: [
					]
				})
			];
			

		}
		
		private var _title:String = "title";
		
		[Bindable]
		public function get title():String
		{
			return _title;
		}
		public function set title(s:String):void
		{
			_title = s;
			if(label) {
				label.text = _title;
				if(label.text=="")
					label.height = 0;
			}
		}
		
		[SkinPart(required="true")]
		public var label:Label;
		
		[Bindable]
		public var fill:SolidColor = new SolidColor(0x444444);
		
		override protected function partAdded(partName:String, instance:Object) : void
		{
			super.partAdded(partName, instance);
			
			if(instance == label) {
				label.text = title;
				if(label.text=="")
					label.height = 0;
			}
		}
		
	}
}