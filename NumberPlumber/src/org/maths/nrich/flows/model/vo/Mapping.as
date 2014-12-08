package org.maths.nrich.flows.model.vo
{
	import flash.net.getClassByAlias;
	
	import mx.controls.Alert;
	import mx.graphics.SolidColor;
	
	import org.maths.XMLUtilities;
	import org.maths.nrich.flows.components.BinaryFlow;
	import org.maths.nrich.flows.components.BinaryMap;
	import org.maths.nrich.flows.components.FeedbackSource;
	import org.maths.nrich.flows.components.Flow;
	import org.maths.nrich.flows.components.FlowGroup;
	import org.maths.nrich.flows.components.InputFlow;
	import org.maths.nrich.flows.components.OutputFlow;
	import org.maths.nrich.flows.components.UnaryFlow;
	import org.maths.nrich.flows.components.UnaryMap;

	/**
	 * Mappings store information about connected Input to Output Flows 
	 */
	public class Mapping
	{

		public var fill:SolidColor;	
		public var inputs:Vector.<InputFlow> = new Vector.<InputFlow>;
		public var flows:Vector.<Flow> = new Vector.<Flow>;
		public var output:OutputFlow;
		public var feedbacks:Vector.<FeedbackSource> = new Vector.<FeedbackSource>;
		
		public static const colourTable:Array = 
			[
				0x006644,
				0x664400,
				0x440066,
				0x004466,
				0x446600,
				0x660044,
				0x000044,
				0x004400,
				0x440000,
				0x002222,
				0x222200,
				0x220022,
				0x007733,
				0x773300,
				0x330077,
				0x003377,
				0x337700,
				0x770033
			];

		public function Mapping(flow:Flow = null)
		{
			if(!flow)
				return;
			
			if(flow is InputFlow) {
				flow.isInput = true;
				inputs[0] = flow as InputFlow;
				if(flow is FeedbackSource) {
					feedbacks.push(flow);
				}
			}
			else if(flow is OutputFlow) {
				flow.isOutput = true;
				output = flow as OutputFlow;
			}
			else
				flows[0] = flow;
		}
		
		public function clone():Mapping
		{
			var mapping:Mapping = new Mapping();
			mapping.feedbacks = feedbacks;
			mapping.inputs = inputs;
			mapping.fill = fill;
			mapping.flows = flows;
			mapping.flowNames = flowNames;
			mapping.xmlWritten = xmlWritten;
			return mapping;
		}
		
		public function get numInputs():int 
		{
			return inputs.length;
		}
		
		public function addInput(input:InputFlow):void
		{
			if(inputs.indexOf(input) < 0) {
//				if(inputs.length >= 2)
//					throw new Error("too many inputs");
				inputs.push(input)
			}
			
			if(input is FeedbackSource && feedbacks.indexOf(input) < 0) {
				feedbacks.push(input)
			}
			
			// update the outputSkin variable names
			renameVariables()
		}
		
		public function renameVariables():void
		{
			if(output) {
				var varNames:Vector.<String> = new Vector.<String>;
				for(var i:int=0; i < inputs.length; i++) {
					varNames[i] = inputs[i].padVariable;
				}
				output.varNames = varNames.sort(function(a:String, b:String):Number{
					if(a==b) return 0;
					if(a < b) return -1;
					return 1;
				});
			}
			
		}
		
		public function inputNamed(varName:String):InputFlow
		{
			for(var i:int=0; i < inputs.length; i++)
			{
				if(inputs[i].padVariable == varName)
					return inputs[i];
			}
			return null;
		}
		
		public function addFlow(flow:Flow):void
		{
			if(flows.indexOf(flow) < 0) {
				flows.push(flow)
			}
		}
		
		public function removeInput(input:InputFlow):void
		{
			var i:int = inputs.indexOf(input);
			if(i >= 0)
				inputs.splice(i, 1);
			
			i = feedbacks.indexOf(input as FeedbackSource);
			if(i >= 0)
				feedbacks.splice(i, 1);
		}

		
		public function removeFlow(flow:Flow):void
		{
			var i:int = flows.indexOf(flow);
			if(i >= 0)
				flows.splice(i, 1);
		}

/*		public function feedback(expr:Expression):void {
			
			for(var i:int=0; i < feedbacks.length; i++) {
				var f:FeedbackSource = feedbacks[i];
				f.arg0 = expr; //f.lastExpression;
				//f.lastExpression = expr;
			}
		}
*/		
		/**
		 * 
		 * @return the mapping name
		 * 
		 */
		public function get name():String {
			return output.name;
		}
		
		/**
		 * 
		 * @param input an input flow
		 * @return the label for the input flow or null if the flow is not an input associated with this mapping.
		 * 
		 */
		public function inputLabel(input:Flow):String {
			var index:int = inputs.indexOf(input);
			if(index < 0) return null;
			return "input "+ (index+1) + " to " + name;
		}
		
		public var xmlWritten:Boolean = false;
		
		public function toXML():XML {
			
			if(xmlWritten) return null;
			xmlWritten = true;
			
			var map:XML;
			
			if(output)
				map = <map id={output.functionName} color={"0x"+output.flowMap.fill.color.toString(16)} />;
			else 
				map = <map />;
				
 			// Append inputs
			for(var i:int = 0; i < inputs.length; i++) {
				map.appendChild(inputs[i].toXML());
			}
			
 			// Append feedbacks
//			for(i = 0; i < feedbacks.length; i++) {
//				map.appendChild(feedbacks[i].toXML());
//			}
			
			// Append unary flows
			for(i = 0; i < flows.length; i++) {
				map.appendChild(flows[i].toXML());
			}
			
			// Append output
			if(output)
				map.appendChild(output.toXML());
			
			return map;
		}
		
		public var flowNames:Object;
		
		public function installFromXML(map:XML, flowGroup:FlowGroup):void {
			flowNames = {};	
			
			var inputsXML:XMLList = map.inputFlow;
			inputs = new Vector.<InputFlow>;
			for(var i:int = 0; i < inputsXML.length(); i++) {
				var flowClassXML:String = XMLUtilities.stringAttr(inputsXML[i].@flow, null);
				if(!flowClassXML) continue;
				try {
					var flowClass:Class = getClassByAlias(flowClassXML);
				}
				catch (e:Error) {
					Alert.show(e.message, "Unrecognised Flow Type", Alert.OK);
					continue;
				}
				var input:InputFlow = new flowClass();
				input.fromXML(inputsXML[i]);
				flowNames[input.id] = input;
				
				inputs[i] = input;
				flowGroup.addElement(input);
			}
			
			var feedbacksXML:XMLList = map.feedback;
			feedbacks = new Vector.<FeedbackSource>;
			for(i = 0; i < feedbacksXML.length(); i++) {
				var feedback:FeedbackSource = new FeedbackSource;
				feedback.fromXML(feedbacksXML[i]);
				flowNames[feedback.id] = feedback;
				feedbacks[i] = feedback;
				flowGroup.addElement(feedback);
			}
			
			// fetch all flows
			flows = new Vector.<Flow>;
			
			// fetch all unary flows
			var list:XMLList = map.unaryFlow;
			for(i=0; i < list.length(); i++) {
				var unaryXML:XML = list[i];
				var unaryFlow:UnaryFlow = new UnaryFlow();
				unaryFlow.fromXML(unaryXML);
				flowNames[unaryFlow.id] = unaryFlow;
				flows.push(unaryFlow);
				flowGroup.addElement(unaryFlow);
			}
					
			// fetch all binary flows
			list = map.binaryFlow;
			for(i=0; i < list.length(); i++) {
				var binaryXML:XML = list[i];
				var binaryFlow:BinaryFlow = new BinaryFlow();
				binaryFlow.fromXML(binaryXML);
				flowNames[binaryFlow.id] = binaryFlow;
				flows.push(binaryFlow);
				flowGroup.addElement(binaryFlow);
			}
			
			// fetch all unary maps
			list = map.unaryMap;
			for(i=0; i < list.length(); i++) {
				unaryXML = list[i];
				var unaryMap:UnaryMap = new UnaryMap();
				unaryMap.fromXML(unaryXML);
				flowNames[unaryMap.id] = unaryMap;
				flows.push(unaryMap);
				flowGroup.addElement(unaryMap);
			}
			
			// fetch all binary maps
			list = map.binaryMap;
			for(i=0; i < list.length(); i++) {
				binaryXML = list[i];
				var binaryMap:BinaryMap = new BinaryMap();
				binaryMap.fromXML(binaryXML);
				flowNames[binaryMap.id] = binaryMap;
				flows.push(binaryMap);
				flowGroup.addElement(binaryMap);
			}
			
			// fetch output flow
			list = map.outputFlow;
			if(list.length() > 0) {
				output = new OutputFlow();
				output.fromXML(list[0]);
				output.tableData = flowGroup.tableData;
				flowNames[output.id]=output;
				flowGroup.addElement(output);
				
				var color:uint = XMLUtilities.uintAttr(map.@color, 0x880000);
				var fill:SolidColor = new SolidColor(color);
				output.flowMap.fill = fill;
				output.setSourceFill(fill);
			}
		}

		
		public function connectFlows(mapXML:XML):void 
		{
			var pf:Vector.<Flow> = new Vector.<Flow>;
			
			var flowList:XMLList = mapXML.children();
			if(!flowList) return;
			for(var i:int = 0; i < flowList.length(); i++) {
				var flowXML:XML = flowList[i];
				if(!flowXML.hookup) continue;
				for(var j:int=0; j < flowXML.hookup.length(); j++) {
					var hookup:SinkSourceLink = SinkSourceLink.newFromXML(flowXML.hookup[j], this);
					if(hookup == null)
						continue;
				}
			}
		}

	}
}