package org.maths.nrich.flows.model.vo
{
	import org.maths.nrich.flows.components.Catcher;
	import org.maths.nrich.flows.components.Flow;
	import org.maths.nrich.flows.components.Sinker;
	import org.maths.nrich.flows.skins.parts.DropPad;
	import org.maths.XMLUtilities;

	public class SinkSourceLink
	{
		public var sinkFlow:Flow;
		public var sink:Sinker;
		public var sourceFlow:Flow;
		public var source:Catcher;
		public var pad:DropPad;
		
		public function SinkSourceLink(
			sinkFlow:Flow,
			sink:Sinker,
			sourceFlow:Flow,
			source:Catcher,
			pad:DropPad)
		{
			this.sinkFlow = sinkFlow;
			this.sink = sink;
			this.sourceFlow = sourceFlow;
			this.source = source;
			this.pad = pad;
		}
		
		public function toXML():XML {
			return <hookup sinkFlow={sinkFlow.name} sourceFlow={sourceFlow.name} padIndex={padIndex} />
		}

		/**
		 * Create a connection from an XML description of it. Both flows must be on stage.
		 * @param xml	a hookup record
		 * @param mapping	The mapping contains names of loaded flows
		 * @return a SinkSourceLink reflecting the state of the connection
		 * 
		 */
		public static function newFromXML(xml:XML, mapping:Mapping):SinkSourceLink
		{
			var sinkFlowName:String = XMLUtilities.stringAttr(xml.@sinkFlow, "null");
			var sinkFlow:Flow = mapping.flowNames[sinkFlowName];
			if(!sinkFlow) return null;
			
			var sink:Sinker = sinkFlow.addSink();
			
			// we're not creating a connection interactively here
			//sink.removeEventHandlers();
			sink.removeMoveHandler();
			sink.stopDrag();
			sink.dragging = false;
			
			var sourceFlowName:String = XMLUtilities.stringAttr(xml.@sourceFlow, "null");
			var sourceFlow:Flow = mapping.flowNames[sourceFlowName];
			if(!sourceFlow) return null;
			
			var padIndex:int = XMLUtilities.intAttr(xml.@padIndex, 0);
			var pad:DropPad = (padIndex == 0 ? sourceFlow.source.pad0 : sourceFlow.source.pad1) as DropPad;
			
			var hookup:SinkSourceLink = new SinkSourceLink(sinkFlow, sink, sourceFlow, sourceFlow.source, pad);
			
			sink.attachment = hookup;
			
			sinkFlow.connectUsing(hookup);
			
			return hookup;
		}
		
		public function get padIndex():int 
		{
			if(pad == source.pad1) return 1;
			else return 0;
		}
	}
}