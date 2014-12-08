package org.maths.nrich.flows.components
{
	import flash.events.Event;
	
	import org.maths.Complex;
	import org.maths.XMLUtilities;
	import org.maths.nrich.flows.interfaces.ISourceSkin;

	public class InputFlow extends Flow
	{
		
		public function InputFlow()
		{
			super();
			isInput = true;
			map.addInput(this);
		}
		
		public function duplicates(f:InputFlow):Boolean
		{
			return className == f.className;
		}
		
		override public function resetValues():void
		{
			for(var i:int=0; i < sinks.length; i++) {
				sinks[i].expression = null;
			}
			invalidateProperties();
		}

		protected function drop(event:Event):void
		{
			if(map.output)
				map.output.run();
		}

/*		private var hrx:int = 0;
		override protected function getHideReveal_x():int
		{
			if(source && source.inPad && source.inPad.invalidPadSize) {
				source.inPad.invalidPadSize = false;
				return hrx = source.width - 5;
			}
			else {
				return hrx
			}
		}
*/
		override protected function getHideReveal_x2():int
		{
			if(source && source.sourceArea) {
				source.sourceArea.validateNow();
				var w:int = Math.max(source.sourceArea.width, (source.skin as ISourceSkin).titleHolder.width);
				return w + 12;
			}
			return 20;
		}
		
		
		override public function toXML():XML {
			
			var xml:XML = super.toXML();
			xml.setName("inputFlow");
			xml.@varName = this.padVariable;
			
			var z:Complex;
			if(arg0) {
				z = arg0.evaluate();
				if(z) xml.@arg0 = z.fullString();
			}
			if(arg1) {
				z = arg1.evaluate();
				if(z) xml.@arg1 = z.fullString();
			}
			
			if(minimum) {
				xml.@minimum = minimum.toString();
			}
			if(maximum) {
				xml.@maximum = maximum.toString();
			}
			
			return xml;
		}
		
		override public function fromXML(xml:XML):void {

			super.fromXML(xml);
			
			var s:String = XMLUtilities.stringAttr(xml.@varName, null);
			if(s) {
				padVariable = s;
			}
			
			minimum = XMLUtilities.intAttr(xml.@minimum, 0);
			maximum = XMLUtilities.intAttr(xml.@maximum, 10);
		}
		

	}
}