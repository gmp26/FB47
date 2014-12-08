package org.maths.nrich.flows.components
{
	import flash.events.Event;
	
	import mx.states.State;
	
	import org.maths.nrich.flows.skins.CollapsiblePanelSkin;
	
	import spark.components.Label;
	import spark.components.SkinnableContainer;
	
	[SkinState('maximised')]
	[SkinState('normal')]
	public class CollapsiblePanel extends SkinnableContainer
	{

		public static const COLLAPSE:String = "collapse";
		public static const EXPAND:String = "expand";
		
		public var title:String;
		
		[SkinPart(required="true")]
		public var label:Label;
		
		function CollapsiblePanel() {
			
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
		
		override protected function partAdded(partName:String, instance:Object) : void
		{
			super.partAdded(partName, instance);
			
			if(instance == label) {
				label.text = title;
			}
			
			skin.addEventListener(CollapsiblePanelSkin.COLLAPSE, collapse)
			skin.addEventListener(CollapsiblePanelSkin.EXPAND, expand)
		}
		
		override protected function partRemoved(partName:String, instance:Object) : void
		{
			super.partRemoved(partName, instance);
			
			skin.removeEventListener(CollapsiblePanelSkin.COLLAPSE, collapse)
			skin.removeEventListener(CollapsiblePanelSkin.EXPAND, expand)
		}
		
		
		override protected function getCurrentSkinState() : String
		{
			return currentState;
		}
		
		public function collapse(event:Event = null):void {
			dispatchEvent(new Event(CollapsiblePanel.COLLAPSE));
			currentState = "normal";
			invalidateSkinState();
		}

		public function expand(event:Event = null):void {
			dispatchEvent(new Event(CollapsiblePanel.EXPAND));
			currentState = "maximised";
			invalidateSkinState();
		}
	}
}