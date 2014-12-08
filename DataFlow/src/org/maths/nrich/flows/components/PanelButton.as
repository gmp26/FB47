package org.maths.nrich.flows.components
{
	import mx.graphics.SolidColor;
	import mx.states.State;
	
	import org.maths.nrich.flows.skins.PanelBarButton;
	
	import spark.components.supportClasses.ButtonBase;
	
	[SkinState('over')]
	[SkinState('up')]
	[SkinState('down')]
	[SkinState('disabled')]
	public class PanelButton extends ButtonBase
	{
		public function PanelButton()
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

		[SkinPart(required="true")]
		public var fill:SolidColor;
		
		private var _colour:uint = 0xff0000;
		[Bindable]
		public function get baseColor():uint 
		{
			return _colour;
		}
		public function set baseColor(colour:uint):void 
		{
			_colour = colour;
			if(panelButtonSkin)
				panelButtonSkin.fill.color = colour;
		}
				
		private var _label:String = "+";
		[Bindable]
		override public function get label():String 
		{
			if(panelButtonSkin)
				return panelButtonSkin.text;
			return _label;
		}
		
		public function set label(s:String):void 
		{
			_label=s;
			if(panelButtonSkin)
				panelButtonSkin.text = s;
		}
		
		override protected function partAdded(partName:String, instance:Object) : void
		{
			if(instance==fill) {
				fill.color = _colour;
				panelButtonSkin.text = _label;
			}
		}
		
		private function get panelButtonSkin():PanelBarButton
		{
			return skin as PanelBarButton;
		}
	}
}