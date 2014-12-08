package org.maths.nrich.flows.components
{
	import mx.states.State;
	
	import org.maths.nrich.flows.skins.SlimButtonSkin;
	
	import spark.components.RichText;
	import spark.components.supportClasses.ButtonBase;
	
	[SkinState('over')]
	[SkinState('up')]
	[SkinState('down')]
	[SkinState('disabled')]
	public class SlimButton extends ButtonBase
	{
		public function SlimButton()
		{
			buttonMode = true;
			useHandCursor=true;
			super();

			this.currentState = "up";
			
			states = [
				new State ({
					name: "up",
					overrides: [
					]
				})
				,
				new State ({
					name: "over",
					overrides: [
					]
				})
				,
				new State ({
					name: "down",
					overrides: [
					]
				})
				,
				new State ({
					name: "disabled",
					overrides: [
					]
				})
			];
		}

		[Bindable]
		public var title:String = "title";
		
		[Bindable]
		public var downtitle:String = "Drop";
		
		[SkinPart(required="true")]
		public var titleLabel:RichText;

		private function get slimButtonSkin():SlimButtonSkin
		{
			return skin as SlimButtonSkin;
		}
	}
}