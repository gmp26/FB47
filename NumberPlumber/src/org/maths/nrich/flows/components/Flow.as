package org.maths.nrich.flows.components
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.getClassByAlias;
	
	import mx.controls.Alert;
	import mx.core.ClassFactory;
	import mx.graphics.SolidColor;
	import mx.messaging.AbstractConsumer;
	import mx.states.State;
	
	import org.maths.Complex;
	import org.maths.Expression;
	import org.maths.MapDef;
	import org.maths.XMLUtilities;
	import org.maths.nrich.flows.interfaces.IDropPad;
	import org.maths.nrich.flows.interfaces.ISourceSkin;
	import org.maths.nrich.flows.model.vo.Mapping;
	import org.maths.nrich.flows.model.vo.SinkSourceLink;
	import org.maths.nrich.flows.skins.FlowSkin;
	import org.maths.nrich.flows.skins.PanelBarButton;
	import org.maths.nrich.flows.skins.parts.DropPad;
	import org.maths.nrich.flows.skins.sources.BinaryMapSkin;
	import org.maths.nrich.flows.skins.sources.BinarySkin;
	import org.maths.nrich.flows.skins.sources.OutputPadSkin;
	import org.maths.nrich.flows.skins.sources.OverSkin;
	import org.maths.nrich.flows.skins.sources.PostFixSkin;
	import org.maths.nrich.flows.skins.sources.UnaryMapSkin;
	import org.maths.nrich.flows.skins.sources.UnarySkin;
	
	import spark.components.Group;
	import spark.components.supportClasses.SkinnableComponent;
	import spark.filters.BlurFilter;
	import spark.primitives.Path;

	[SkinState("normal")]
	[SkinState("over")]
	[SkinState("selected")]
	[SkinState("selectedOver")]
	public class Flow extends SkinnableComponent
	{
		
		public static const RELAYOUT_PLACEHOLDERS:String = "relayoutPlaceholders";
		
		public const defaultFill:SolidColor = new SolidColor(0x999999);
		
		public var arity:int = 1;
		
		function Flow()
		{
			super();

			if(this is OutputFlow)
				isOutput = true;
			
			if(this is InputFlow)
				isInput = true;
			
			map = new Mapping(this);
			
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
					name: "over",
					overrides: [
					]
				})
				,
				new State ({
					name: "selected",
					overrides: [
					]
				})
				,
				new State ({
					name: "selectedOver",
					overrides: [
					]
				})
			];
		
			addEventListener(Event.ADDED_TO_STAGE, addListeners);
			addEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
		}
				
		private function addListeners(event:Event = null):void {
			addEventListener(MouseEvent.MOUSE_DOWN, elevate);
			addEventListener(MouseEvent.MOUSE_UP, select);
			addEventListener(MouseEvent.ROLL_OVER, over);
			addEventListener(MouseEvent.ROLL_OUT, out);
		}
		
		private function removeListeners(event:Event = null):void {
			removeEventListener(MouseEvent.MOUSE_DOWN, elevate);
			removeEventListener(MouseEvent.MOUSE_UP, select);
			removeEventListener(MouseEvent.ROLL_OVER, over);
			removeEventListener(MouseEvent.ROLL_OUT, out);
		}
		
		private var _selected:Boolean = false;
		[Bindable]
		public function get selected():Boolean
		{
			return _selected;
		}
		public function set selected(value:Boolean):void
		{
			_selected = value;
			if(value && !decorator && mouseIsOver)
				addDecorator();
			invalidateProperties();
		}
		
		public var mouseIsOver:Boolean = false;
		
		/**
		 *  @private
		 */
		override protected function getCurrentSkinState():String
		{
			if (selected) {
				if(mouseIsOver)
					return "selectedOver"
				else
					return "selected"
			}
			else {
				if(mouseIsOver)
					return "over"
				else
					return "normal"
			}
		}
		
				
		[Bindable]
		public var isInput:Boolean = false;
		
		[Bindable]
		public var isOutput:Boolean = false;

		
		public function get isDraggable():Boolean
		{
			return true; //!(isInput);
		}
		
		protected var map:Mapping;
		
		public function setMapping(newMap:Mapping):void {
			
			if(isInput) {
				var input:InputFlow = this as InputFlow;
				map.removeInput(input);
				newMap.addInput(input);
			}
			else {			
				map.removeFlow(this);
				newMap.addFlow(this);
			}
			if(isOutput && map.fill) {
				throw new Error("Cannot change an output mapping");
			}
			
			map = newMap;
			setSourceFill(newMap ? newMap.fill : defaultFill);
		}
		
		public function get sourceFill():SolidColor
		{
			return source.sourceFill;
		}
		
		public function setSourceFill(fill:SolidColor):void {
			if(source) source.sourceFill = fill ? fill : defaultFill;
			source.invalidateProperties();			
		}
		
		private function get outputFill():SolidColor{
			return map? map.fill : defaultFill;
			
			//var of:OutputFlow = outputFlow;
			//return of ? of.sourceFill : defaultFill;
		}
		
		private function get inputFlow():InputFlow
		{
			if(isInput)
				return this as InputFlow;
			
			for(var i:int = 0; i < previousFlows.length; i++) {
				var f:Flow = previousFlows[i].inputFlow;
				if(f)
					return f as InputFlow;
			}
			
			return null;
		}
		
		private function get outputFlow():OutputFlow
		{
			if(isOutput)
				return this as OutputFlow;
			
			for(var i:int=0; i < nextFlows.length; i++) {			
				var f:Flow = nextFlows[i];
				var out:OutputFlow = f.outputFlow;
				if(out != null)
					return out;
			}
			
			return null;
		}
		
		public function get flowMap():Mapping
		{
			return map;
		}
		
		// Flow loop detection
//		public var crumbColour:uint = 0;
		
		[Bindable]
		public var sourceSkin:Class;
				
		
		[SkinPart(required="true")]
		public var source:Catcher;
		
		[SkinPart(required="false", type="org.maths.nrich.dataflow.view.components.flowparts.Sinker")]
		public var sink:ClassFactory = new ClassFactory(Sinker);
		
		// For pre-step checking
		public var arg0Ready:Boolean = false;
		public var arg1Ready:Boolean = false;

		protected var _arg0:Expression;
		public function get arg0():Expression {
			if(source)
				return _arg0 = source.arg0;
			else
				return _arg0;
		}
		public function set arg0(s:Expression):void {
			_arg0 = s;
			if(source) {
				source.arg0 = s;
				if(source.inPad)
					source.inPad.invalidPadSize = true;
			}
			
			invalidateProperties();
		}
		
		
		private var _op:String;
		public function get op():String {
			if(source && source.op)
				return (_op = source.op);
			else
				return _op;
		}
		public function set op(s:String):void {
			_op = s;
			if(source) 
				source.op = s;
			invalidateProperties();
		}
		
		private var _arg1:Expression;
		public function get arg1():Expression {
			if(source)
				return _arg1 = source.arg1;
			else
				return _arg1;
		}
		public function set arg1(s:Expression):void {

			_arg1 = s;
			if(source) 
				source.arg1 = s;
			invalidateProperties();
		}
		
		protected var _minimum:Number = 0;
		[Bindable]
		public function get minimum():Number
		{
			if(source && source.inPad)
				return source.inPad.minimum;
			return _minimum;
			
		}
		public function set minimum(n:Number):void
		{
			_minimum = n;
			if(source && source.inPad)
				source.inPad.minimum = n;
			invalidateProperties();
		}
		
		protected var _maximum:Number = 0;
		[Bindable]
		public function get maximum():Number
		{
			if(source && source.inPad)
				return source.inPad.maximum;
			return _maximum;
			
		}
		public function set maximum(n:Number):void
		{
			_maximum = n;
			if(source && source.inPad)
				source.inPad.maximum = n;
			invalidateProperties();
		}
		
		protected var _padVariable:String = "x";
		public function get padVariable():String
		{
			if(source && source.inPad)
				return source.inPad.padVariable;
			return _padVariable;
			
		}
		public function set padVariable(s:String):void
		{
			_padVariable = s;
			if(source && source.inPad)
				source.inPad.padVariable = s;
			invalidateProperties();
		}
		
		private var _showValues:int = 0;
		public function get showValues():int
		{
			return _showValues;
		}
		public function set showValues(value:int):void
		{
			_showValues = value;
			// set the source displaymode
			source.showValues = value;
			
			// Set any sink display mode
			for(var i:int = 0; i < sinks.length; i++) {
				sinks[i].showValues = value;
			}
			
			invalidateProperties();
		}
		
		public var sinks:Vector.<Sinker> = new Vector.<Sinker>();
		
		public function addSink():Sinker
		{
			var sink:Sinker = createDynamicPartInstance("sink") as Sinker;
			return sink;
		}
		
		/**
		 * 
		 * @param sink
		 * @param dropTarget
		 * @return 
		 * 
		 */
		public function dropOn(sink:Sinker, dropTarget:DisplayObject):Object
		{
			sink.attachment = null;
			var hookup:SinkSourceLink = null;
			
			if(dropTarget != flowGroup) {
				
				hookup = flowGroup.findCatcher(this, sink, dropTarget);
				if(hookup) {
					
					return connectUsing(hookup);
				}
			}
			return null;

		}
		
		public function connectUsing(hookup:SinkSourceLink):SinkSourceLink
		{
			var targetMap:Mapping = hookup.sourceFlow.map;
			
			/*
			Case 1: map and target both null
			connect without recolour
			
			Case 2: target has map
			Case 2.1: I am an input
			Case 2.1.1: target already has 2 inputs
			disallow connection
			Case 2.1.2:
			connect, this.floodMap()
			Case 2.2
			connect, this.floodMap()
			
			Case 3: I have map, target is null:
			connect, target.floodMap()
			
			Case 4: I have map, target has map
			disallow
			*/
			
			// check whether target already has two inputs; need to count the union
			var uniqueInputs:Object = {};
			for(var i:int=0; i < map.inputs.length; i++) {
				if(map.inputs[i] is MemoryRegister)
					continue;
				uniqueInputs[map.inputs[i].name] = i;
			}
			for(i=0; i < targetMap.inputs.length; i++) {
				if(targetMap.inputs[i] is MemoryRegister)
					continue;
				uniqueInputs[targetMap.inputs[i].name] = i;
			}
			var numInputs:int = 0;
			for(var n:String in uniqueInputs) ++numInputs;
			
			
			if(numInputs > 2) {	
				Alert.show("Too many inputs", "Cannot connect", Alert.OK, flowGroup);
				return null;
			}
			
			// The two maps are the same: Connect if there is no loop...
			if(hookup.sourceFlow.hasSuccessor(this)) {
				Alert.show("Loops are not allowed", "Cannot connect", Alert.OK, flowGroup);
				return null;
			}
			
			//	map and target both null
			//		connect maps
			if(map.fill == null && targetMap.fill == null) {
				floodMap(hookup.sourceFlow.map);						
				moveSinkToPad(hookup);
				//backPropagate();
				return hookup;
			}
			
			// I have map and target has map
			if(map.fill && targetMap.fill) {
				if(map != targetMap) {
					Alert.show("Don't mix colours", "Cannot connect", Alert.OK, flowGroup);
					return null;
				}
				else {
					
					moveSinkToPad(hookup);
					//backPropagate();
					return hookup;
				}
			}
			
			// I have map, target map is empty 
			if(map.fill) {
				moveSinkToPad(hookup);
				hookup.sourceFlow.floodMap(map);
				//backPropagate();
				return hookup;
			}
			
			// Cases 2.1.2, 2.2
			if(targetMap.fill) {
				floodMap(hookup.sourceFlow.map);
				moveSinkToPad(hookup);
				//backPropagate();
				return hookup;
			}
			
			return null;
		}
		
		private function moveSinkToPad(hookup:SinkSourceLink):void {
			var source:Catcher = hookup.source;
			var pad:IDropPad = hookup.pad;
			var sink:Sinker = hookup.sink;
			var local:Point = (source.skin as ISourceSkin).padContainer.localToGlobal(new Point(pad.x, pad.y));
			var local2:Point = globalToLocal(local);
			sink.x = local2.x;
			sink.y = local2.y;

			
			if(pad == source.pad0)
				hookup.sourceFlow.arg0 = sink.expression;
			else if(pad == source.pad1)
				hookup.sourceFlow.arg1 = sink.expression;
			
			sink.attachment = hookup;
			attachPredecessorToNextSource(hookup);

		}
		
		/**
		 * Bring this flow to the front, then chain back towards the inputs bringing
		 * each of them to the front. The end result should be that sinks are layered 
		 * on top of the DropPads they feed.
		 */
		public function backPropagate():void
		{
			bringToTop();
			for(var i:int=0; i < previousFlows.length; i++) {
				var f:Flow = previousFlows[i];				
				f.backPropagate();
			}
		}
		
		public function floodMap(newMap:Mapping, depth:int=0, recolour:Boolean = false):Mapping
		{
			var i:int = 0;
			
			if(depth > 50)
				trace("BREAKPOINT");
			
			//trace("\nNode", name, ", Depth =",depth);
			if(map == newMap)
				return newMap;

			// ignore the input parameter and use the output map if this is an output
			if(isOutput) {
//				trace("=Output=");
				
				// flood predecessors
				if(recolour) {
					for(i = 0; i < this.previousFlows.length; i++) {
						var f:Flow=previousFlows[i];
						f.floodMap(newMap, depth+1);
					}
				}
				else {
					for(i = 0; i < this.previousFlows.length; i++) {
						f=previousFlows[i];
						newMap = f.floodMap(map, depth+1);
					}
				}
				
				return newMap;
			}
			
			//trace("setMapping:", newMap.fill);
			setMapping(newMap);
			
			// flood predecessors
			for(i = 0; i < this.previousFlows.length; i++) {
				f=previousFlows[i];
				//trace("p[",f.name,"], map =",f.map.fill,", newMap =",newMap.fill)
				newMap = f.floodMap(newMap, depth+1);
			}
			
			// flood successors
			for(i = 0; i < this.nextFlows.length; i++) {
				f=nextFlows[i];
				//trace("n[",f.name,"], map =",f.map.fill,", newMap =",newMap.fill)
				newMap = f.floodMap(newMap, depth+1);
			}
			
			return newMap;
		}

		
		/**
		 * 
		 * @return a vector of flows on which we drop our value.
		 * 
		 */
		public function get nextFlows():Vector.<Flow> 
		{
			var flows:Vector.<Flow> = new Vector.<Flow>;
			for(var i:int = 0; i < sinks.length; i++) {
				var hookup:SinkSourceLink = sinks[i].attachment;
				if(hookup)
					flows.push(hookup.sourceFlow);
			}
			return flows;
		}
		
		private var _previousFlows:Vector.<Flow>;
		
		public function get previousFlows():Vector.<Flow>
		{
			if(_previousFlows == null) {
				_previousFlows = flowGroup.predecessorsOf(this);
			}
			return _previousFlows;
		}
		
		public function hasSuccessor(flow:Flow):Boolean
		{
			var nFlows:Vector.<Flow> = nextFlows;
			if(nFlows.indexOf(flow) >= 0)
				return true;
			
			for(var i:int = 0; i <nFlows.length; i++) {
				if(nFlows[i].hasSuccessor(flow))
					return true;
			}
			
			return false;
		}
		
		public function hasPredecessor(flow:Flow):Boolean
		{
			var pFlows:Vector.<Flow> = previousFlows;
			if(pFlows.indexOf(flow) >= 0)
				return true;
			
			for(var i:int = 0; i <pFlows.length; i++) {
				if(pFlows[i].hasSuccessor(flow))
					return true;
			}
			
			return false;
		}
		
		public function removeSink(sink:Sinker):void
		{
			removeDynamicPartInstance("sink", sink);
		}
		
		public function detachPredecessor(hookup:SinkSourceLink):void
		{
			
			var pad:IDropPad = hookup.pad;
			if(pad == source.pad0)
				arg0 = null;
			if(pad == source.pad1)
				arg1 = null;
			
			// We only want to disconnect when ALL predecessors have gone so we'd better recalculate
			// from first principles.
			_previousFlows = flowGroup.predecessorsOf(this);
			
			//var i:int = previousFlows.indexOf(hookup.sinkFlow);
			//if(i >= 0) 
			//	previousFlows.splice(i,1);
			
			invalidateProperties();
		}
		
		public function attachPredecessorToNextSource(hookup:SinkSourceLink):void
		{
			var nextPF:Vector.<Flow> = hookup.sourceFlow.previousFlows;
			if(nextPF.indexOf(this) < 0)
				nextPF.push(this);
		}
		
		public function removeMe(event:MouseEvent = null):void {
			var pFlows:Vector.<Flow> = previousFlows.concat();
			for(var i:int = 0; i < pFlows.length; i++) {
				var f:Flow = pFlows[i];
				while(f.sinks.length > 0) {
					var sink:Sinker = f.sinks.pop();
					f.unlink(sink.attachment);
					f.removeSink(sink);
				}
			}
			while(sinks.length > 0) {
				sink = sinks.pop();
				this.unlink(sink.attachment);
				this.removeSink(sink);
			}
			flowGroup.removeElement(this);
		}
		
		public function unlink(hookup:SinkSourceLink):void
		{
			hookup.sink.attachment = null;
			hookup.sourceFlow.detachPredecessor(hookup);
			
			
			// Remap the sink's flow (i.e. this)
			floodMap(new Mapping(this));
			
			// Remap the source's flow
			if(map != hookup.sourceFlow.map)
				hookup.sourceFlow.floodMap(new Mapping(hookup.sourceFlow));		

		}
		
		
		public function resetValues():void
		{
			var pFlows:Vector.<Flow> = previousFlows;
			for(var i:int = 0; i < pFlows.length; i++) {
				var f:Flow = pFlows[i];
				for(var j:int = 0; j < f.sinks.length; j++) {
					var sink:Sinker = f.sinks[j];
					var hookup:SinkSourceLink = sink.attachment;
					if(hookup.sourceFlow == this) {
						if(hookup.pad == source.pad0)
							arg0 = null;
						if(hookup.pad == source.pad1)
							arg1 = null;
					}
				}
			}
			
			//arg0 = null;
			//arg1 = null;
			for(i=0; i < sinks.length; i++) {
				sinks[i].expression = null;
			}
			invalidateProperties();
		}
		
		public function get flowGroup():FlowGroup
		{
			var p:DisplayObjectContainer = parent;
			while(p != null && !(p is FlowGroup))
				p = p.parent;
			return p as FlowGroup;
		}
		
		public function get flowSkin():FlowSkin
		{
			return skin as FlowSkin;
		}
		
		/**
		 * Respond to source and sink part additions by initialising them 
		 * @param partName
		 * @param instance
		 * 
		 */
		override protected function partAdded(partName:String, instance:Object):void { 
			super.partAdded(partName, instance); 
			
//			trace(partName, "added");
			if (instance == source) {
				//source.flowGroup = flowGroup;
				source.op = _op;
				source.arg0 = _arg0;
				source.arg1 = _arg1;
				if(source.inPad) {
					source.inPad.padVariable = _padVariable;
					source.inPad.minimum = _minimum;
					source.inPad.maximum = _maximum;
				}
				
//				source.addEventListener(MouseEvent.MOUSE_OVER, addDecorator);
//				source.addEventListener(MouseEvent.MOUSE_OUT, removeDecorator);
				
/*				if(source.pad0)
					source.pad0.expression = arg0;
				if(source.pad1)
					source.pad1.expression = arg1;
*/			} 
			
			if (partName == "sink") {
				
				var sink:Sinker = instance as Sinker;
				sinks.push(sink);	
				//sink.flowGroup = flowGroup;
				sink.fill = source.flowColour;
				sink.stroke = source.flowStroke;
				sink.fontSize = source.fontSize;
				flowSkin.selectableGroup.addElement(sink);
				var point:Point = sourceDragPoint;
				
				var path:Path = sink.flowPath;
				flowSkin.selectableGroup.addElementAt(path, 0);

				// validateNow ensures sink.width and height are correct
				flowSkin.validateNow();
				
				if(source.dragSpot) {
					sink.x = point.x - sink.width/2;
					sink.y = point.y - sink.height/2;
				}
				
				// Add event handlers
				sink.addEventHandlers();
				sink.startDragging();
			} 

		}
		
		override protected function partRemoved(partName:String, instance:Object) : void 
		{
//			trace(partName, "removed");
			if(partName == "sink") {
				
				var sink:Sinker = instance as Sinker;
				
				flowSkin.selectableGroup.removeElement(sink);
				flowSkin.selectableGroup.removeElement(sink.flowPath);				
				
				sink.removeEventHandlers();
				var i:int = sinks.indexOf(sink);
				if(i >= 0)
					sinks.splice(i, 1);

				selected = false;
				mouseIsOver = false;
				
			}
		}
		
		private function get sourceDragPoint():Point
		{
			var spot:DragSpot = source.dragSpot;
			return flowSkin.globalToLocal(spot.localToGlobal(new Point(spot.width/2, spot.height/2)));
		}
		

		/**
		 * Move this component to the top level. 
		 * Apparently you don't need to call removeElement too.
		 * 
		 * @param event
		 * 
		 */
		public function bringToTop(event:Event = null):void {
			if(flowGroup) flowGroup.addElement(this);
		}
		
		public function elevate(event:Event = null):void {
			if(flowGroup) {
				flowGroup.addElement(this);
			}
		}
		
		public function select(event:Event = null):void {
			if(flowGroup) {
				flowGroup.deselectAllBut(this);
				//trace("inputs:"+map.numInputs+"feedbacks:"+(map.feedbacks?map.feedbacks.length:0)+" flows:"+(map.flows?map.flows.length:map.flows)+" outputs:"+map.output); 
				if(map.output)
					map.output.backPropagate();
				else
					backPropagate();
				selected = true;
			}
		}
		
		protected var decorator:Group;
			
		private function addDecorator(event:MouseEvent = null):void
		{
			if(decorator)
				removeDecorator();
			
//			if(!selected)
//				return;
			
			var removeButton:PanelButton = new PanelButton();
			removeButton.x = -11;
			removeButton.y = 12;
/*			removeButton.x = 5;
			removeButton.y = -7;*/
			removeButton.baseColor = 0xff0000;
			removeButton.setStyle("skinClass", PanelBarButton);
			removeButton.label = "x";
			removeButton.addEventListener(MouseEvent.CLICK, removeMe);
			
			var hideRevealButton:PanelButton = new PanelButton();
			if(source) {
				source.validateNow();
			}
			hideRevealButton.x = getHideReveal_x2();
			//hideRevealButton.x = source.sourceArea.width - 5;
			
			hideRevealButton.y = 12;
			hideRevealButton.baseColor = 0x990099;
			hideRevealButton.setStyle("skinClass", PanelBarButton);
			hideRevealButton.label = "?";
			hideRevealButton.addEventListener(MouseEvent.CLICK, hideReveal);
			
			decorator = new Group();
			decorator.addElement(removeButton);
			decorator.addElement(hideRevealButton);
			(source.skin as Group).addElement(decorator);
		}
		
/*		protected function getHideReveal_x():int
		{
			if(source) {
				source.validateNow();
			}
			return source.width - 9;
		}
*/		
		protected function getHideReveal_x2():int
		{
			if(source && source.sourceArea) {
				source.sourceArea.validateNow();
			}
			return source.sourceArea.width - 9;
		}
		
		public function updateDecorator():void {
			if(decorator) decorator.getElementAt(1).x = getHideReveal_x2();
		}
		
		[Bindable]
		public function get hidden():Boolean 
		{
			return filters.indexOf(blurFilter) >= 0;
		}
		public function set hidden(b:Boolean):void
		{
			if(b != (filters.indexOf(blurFilter) >= 0))
				hideReveal();
		}
		
		private var blurFilter:BlurFilter = new BlurFilter(10,12,4);
		
		private function hideReveal(event:MouseEvent = null):void {
			var f:Array = filters;
			var i:int = f.indexOf(blurFilter);
			if(i >= 0) {
				f.splice(i,1);
				alpha=1;
			}
			else {
				alpha=0.3;
				f.push(blurFilter);
			}
			filters = f;
			
		}
		
		private function removeDecorator(event:MouseEvent = null):void
		{
			if(decorator) 
				(source.skin as Group).removeElement(decorator);
			decorator = null;
		}
		
		public function get padFeeds():Object
		{
			var feeds:Object = {};
			var pFlows:Vector.<Flow> = previousFlows;
			for(var i:int = 0; i < pFlows.length; i++) {
				var flow:Flow = pFlows[i];
				for(var j:int = 0; j < flow.sinks.length; j++) {
					var sink:Sinker = flow.sinks[j];
					var hookup:SinkSourceLink = sink.attachment;
					if(hookup.sourceFlow == this) {
						if(hookup.pad == source.pad0)
							feeds["pad"+0] = flow;
						else
							feeds["pad"+1] = flow;
					}
				}
			}
			return feeds;
		}
		
		public function fillInMapDef(mapDef:MapDef, expression:Expression):Boolean
		{
			if(isOutput)
				mapDef.functionName = (this as OutputFlow).functionName;
			
			var e:Expression;

			if(isInput) {
				var input:InputFlow = this as InputFlow;
				mapDef.addDummyVar(input.padVariable);
				expression.type=Expression.VARIABLE;
				expression.name=input.padVariable;
				return true;
			}

			// Work out the default arity of the generated expression.
			// This may be reduced if some of the arguments are constant
			switch(arity) {
				case 0:
					expression.type = Expression.CONSTANT;
					break;
				case 1:
					expression.type = Expression.UNARY;
					break;
				default:
					expression.type = Expression.BINARY;
			}
			expression.name = op;

			// Count the total number of sinks that feed us
			var feeds:Object = padFeeds;
			var feedCount:int = 0;
			for(var p:String in feeds) {
				feedCount++;
			}
			
			var pFlows:Vector.<Flow> = previousFlows;
			switch(feedCount) {
				
				case 0:						
					if(arg0) {
						// This is just a constant
						e = new Expression({type:Expression.CONSTANT, name:"real", value:arg0.evaluate()});
						expression.expr0 = e;
						if(arity == 1) return true;
					}
					if(arity == 1) return false;
					if(arg1) {
						// Also a constant
						e = new Expression({type:Expression.CONSTANT, name:"real", value:arg1.evaluate()});
						expression.expr1 = e;
						return true;						
					}
					// We're missing an arg - so we can't define a mapping
					return false;
					
				case 1:
					var flow:Flow = pFlows[0];
					if(arity == 1) {
						return flow.fillInMapDef(mapDef, expression.expr0 = new Expression(null));
					}
					else {
						// arity 2, but only 1 incoming flow - need to determine which pads are fed feeds and check
						// whether the other one has a valid constant.
						if(feeds.pad0) {
							if(arg1) {
								// arg1 is a constant
								expression.expr1 = new Expression({type:Expression.CONSTANT, name:"real", value:arg1.evaluate()});
								return  flow.fillInMapDef(mapDef, expression.expr0 = new Expression(null));
							}
							else return false;
						}
						else if(feeds.pad1) {
							if(arg0) {
								// arg0 is a constant
								expression.expr0 = new Expression({type:Expression.CONSTANT, name:"real", value:arg0.evaluate()});
								return flow.fillInMapDef(mapDef, expression.expr1 = new Expression(null));
							}
							else return false;
						}
						return false;
					}
								
/*						for(var i:int = 0; i < flow.sinks.length; i++) {
							var sink:Sinker = flow.sinks[i];
							var hookup:SinkSourceLink = sink.attachment;
							if(hookup.sourceFlow == this) {
								if(hookup.pad == source.pad0) {
									if(arg1) {
										// arg1 is a constant
										expression.expr1 = new Expression({type:Expression.CONSTANT, name:"real", value:arg1.evaluate()});
										return  flow.fillInMapDef(mapDef, expression.expr0 = new Expression(null));
									}
									else return false;
								}
								else {
									if(arg0) {
										// arg0 is a constant
										expression.expr0 = new Expression({type:Expression.CONSTANT, name:"real", value:arg0.evaluate()});
										return flow.fillInMapDef(mapDef, expression.expr1 = new Expression(null));
									}
									else return false;
								}
							}
						}
					}
					return false;
*/					
				case 2:
					return feeds.pad0.fillInMapDef(mapDef, expression.expr0 = new Expression(null)) 
					&& feeds.pad1.fillInMapDef(mapDef, expression.expr1 = new Expression(null));
					
/*					// arity 2, with 2 incoming flow - need to determine which flow feeds which pad
					flow = pFlows[0];
					for(i = 0; i < flow.sinks.length; i++) {
						sink = flow.sinks[i];
						hookup = sink.attachment;
						if(hookup.sourceFlow == this) {
							if(hookup.pad == source.pad0) {
								//flow0 feeds pad0
								return flow.fillInMapDef(mapDef, expression.expr0 = new Expression(null)) 
									&& pFlows[1].fillInMapDef(mapDef, expression.expr1 = new Expression(null));
							}
							else {
								//flow0 feeds pad1
								return pFlows[1].fillInMapDef(mapDef, expression.expr0 = new Expression(null)) 
									&& flow.fillInMapDef(mapDef, expression.expr1 = new Expression(null));
							}
						}
					}	
					return false;
*/					
				default:
					return false;						
			}
		}
				
		/**
		 * Returns the expression that represents this flow. Sub expressions will represent
		 * preceding flows. 
		 * @param substituteVars If substituteVars is true, variables are replaced by their values. 
		 * @return the resulting compound expression.
		 * 
		 */
		public function getCompoundExpression(substituteVars:Boolean = false):Expression
		{
			var exprType:int;
			var compound:Expression;
			var w:Complex = null;
			
			if(arg0 == null)
				return null;
			
			if(arity==2) {
				exprType = Expression.BINARY;
				if(arg1 == null)
					return null;
			}
			else if(arity==1) {
				exprType = Expression.UNARY;
			}
			else {
				if(arg0 == null)
					return null;
				return new Expression(arg0.evaluate(substituteVars));
			}
			
			return new Expression({
				type: exprType,
				name: op,
				expr0: arg0,
				expr1: arg1
			})
		}


		public function evaluate(arg0:String, op:String, arg1:String):String {
			if(op == null)
				return arg0;
//			var z:Complex = new Complex(1);
//			if(z[op] is Function) {
				if(arg0 == "" || arg0==null)
					return "";
				if(arg1 == null) {
					return (new Expression(op + "(" + arg0 + ")")).evaluate().fullString();
				}
				else {
					if(arg1 == "")
						return "";
					return (new Expression("(" + arg0 +")" + op + "(" + arg1 + ")")).evaluate().fullString();
				}
//			}
//			else {
				// It may be a defined function.
//				var mapDef:MapDef = Expression.getMapDef(op);
//				if(mapDef) {
//					return mapDef.evaluate(new Expression(arg0), new Expression(arg1)).fullString(); 
//				}
//			}
//			return "Error";
		}				
				
		public function resetForStep():void
		{
			// override in BinaryFlow and in Binary Map
			var x:int=1;
		}
		
		public function preStepCheck():Boolean
		{
			if(arity==1)
				return arg0 != null;
			if(arity==2)
				return arg0 != null && arg1 != null;
			throw new Error("unknown arity: "+arity);
			return false; //arg0 != null;
		}
		
		/**
		 * Evaluate the sink and drop the result on the next source
		 */
		public function step(afterDrop:Boolean = false):void
		{
			if(flowGroup && flowGroup.paused.visible)
				return;
			
			var value:Expression = getCompoundExpression();

			if(!value)
				return;
			
			validateNow();
			select();
					
			var len:int = sinks.length;
			for(var i:int = 0; i < len; i++) {
				var sink:Sinker = sinks[i];
				sink.showValues = showValues;
				animateStep(sinks[i], value, false, true, true);
			}
			
			invalidateDisplayList();			
		}
		
		protected function animateStep(sink:Sinker, value:Expression, valThis:Boolean=true, valSink:Boolean=true, valSource:Boolean=true):void {
			if(valThis) this.validateNow();
			if(valSink) sink.validateNow();
			if(valSource) source.validateNow();
			var from:Point = sourceDragPoint; 
			var to:Point = new Point(sink.x+sink.width/2, sink.y+sink.height/2-5);
			var added:Point = from.add(to);
			var mid:Point = new Point(added.x/2, added.y/2);
			var midStroke:Number = source.flowStroke.weight/2;
			
			var marble:Marble = allocateMarble(); //new Marble();
			marble.duration = flowGroup.dropTime;
			marble.parentFlow = this;
			marble.x = from.x;
			marble.y = from.y;
			marble.sink = sink;
			if(value)
				marble.value = value.clone();
			marble.path = [
				{x:from.x}, {y:mid.y},
				{x:mid.x}, {y:mid.y},
				{x:to.x}, {y:mid.y},
				{x:to.x}, {y:to.y}
			];
			flowSkin.selectableGroup.addElement(marble);
			marble.drop();

		}
		
		private var marbles:Vector.<Marble> = new Vector.<Marble>;
		private function allocateMarble():Marble
		{
			for(var i:int = 0; i < marbles.length; i++) {
				if(marbles[i].path == null)
					return marbles[i];
			}
			var marble:Marble = new Marble();
			marbles.push(marble);
			return marble;
		}
		
		public function removeMarble(marble:Marble):void
		{
			var hookup:SinkSourceLink = marble.sink.attachment;
			var f:Flow = hookup.sourceFlow;
			marble.sink.expression = marble.value;
			if(hookup.pad == f.source.pad0) {
				f.source.arg0 = marble.value;
				f.arg0Ready = true;
			}
			else if(hookup.pad == f.source.pad1) {
				f.source.arg1 = marble.value;
				f.arg1Ready = true;
			}
			
//			trace("removing",marble.name,"from",f.name);
			f.invalidateDisplayList();
			if(f.preStepCheck())
				f.step(true);
			else
				trace("step blocked");
			
			flowSkin.selectableGroup.removeElement(marble);
			marble.path = null;
		}
		
		public function updatePath(sink:Sinker, valThis:Boolean=true, valSink:Boolean=true, valSource:Boolean=true):void {
			if(valThis) this.validateNow();
			if(valSink) sink.validateNow();
			if(valSource) source.validateNow();
			var from:Point = sourceDragPoint; 
			var to:Point = new Point(sink.x+sink.width/2, sink.y+sink.height/2-5);
			var added:Point = from.add(to);
			var mid:Point = new Point(added.x/2, added.y/2);
			var midStroke:Number = source.flowStroke.weight/2;
			var s:String = "";
			s += "M " + from.x + " " + from.y;
			s += " C " + from.x + " " + mid.y + " " + from.x + " " + mid.y + " " + mid.x + " " + mid.y;
			s += " C " + to.x + " " + mid.y + " " + to.x + " " + mid.y + " " + to.x + " " + to.y;
			sink.flowPath.data = s;
		}
		
		public function updateAllPaths():void {
			
			if(!flowGroup) return;
						
			validateNow();

			/* Update incoming paths */
			for(var i:int = 0; i < previousFlows.length; i++) {
				var flow:Flow = previousFlows[i];
				if(!flow) continue;
				var fsl:int = flow.sinks.length;
				for(var j:int = 0; j < fsl; j++) {
					var flowSink:Sinker = flow.sinks[j];
					if(flowSink.attachment && flowSink.attachment.sourceFlow == this) {
						var hookup:SinkSourceLink = flowSink.attachment;
						var sinkFlow:Flow = hookup.sinkFlow;
						sinkFlow.moveSinkToPad(hookup);
						sinkFlow.updatePath(hookup.sink, false, false, true);
					}
				}
			}
			
			/* Update outgoing paths */
			for(i = 0; i < sinks.length; i++) {
				updatePath(sinks[i], false, true, false);
			}
		}
		
		override protected function commitProperties() : void
		{
/*			placeHolder.width = source.width;
			placeHolder.height = source.height;
			placeHolder.attachment = this;
*/			
			invalidateSkinState();
			
/*			if(isInput || isOutput) {
				dispatchEvent(new Event(RELAYOUT_PLACEHOLDERS));
			}
*/					
			super.commitProperties();
			if(decorator)
				updateDecorator();
			updateAllPaths();
		}
		
/*		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number) : void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
*/		
		//public var placeHolder:PlaceHolder = new PlaceHolder();
		
		// State changes
		private function over(event:MouseEvent):void {
			mouseIsOver = true;
			addDecorator();
			invalidateProperties();
			//trace(currentState);
		}
		
		private function out(event:MouseEvent):void {
			mouseIsOver = false;
			removeDecorator();
			invalidateProperties();
			//trace(currentState);
		}
		
		
		public function toXML():XML {
			
			var p:Point = new Point(source.skin.x, source.skin.y);
			p = source.skin.localToGlobal(p);
			p = flowSkin.globalToLocal(p);
			
			var flowXML:XML = <flow id={name} x={x+source.x} y={y+source.y} hide={hidden}/>;
			
			flowXML.@flow = className.substr(0,1).toLowerCase() + className.substr(1);
			
			if(op)
				flowXML.@op = op;

			// save arg values if there is no incoming feed
			var feeds:Object = padFeeds;
			var z:Complex;
			if(!padFeeds.pad0 && arg0) {
				z = arg0.evaluate();
				if(z) flowXML.@arg0 = z.fullString();
			}
			if(!padFeeds.pad1 && arg1) {
				z = arg1.evaluate();
				if(z) flowXML.@arg1 = z.fullString();
			}
			
			// append hookups
			for(var i:int=0; i < sinks.length; i++) {
				flowXML.appendChild(sinks[i].attachment.toXML());	
			}
						
			return flowXML;
		}
		
		public function fromXML(flowXML:XML):void {
			
			x = XMLUtilities.intAttr(flowXML.@x, 200);
			y = XMLUtilities.intAttr(flowXML.@y, 200);
			
			var s:String = XMLUtilities.stringAttr(flowXML.@id, null);
			if(s) id = s;
			
			s = XMLUtilities.stringAttr(flowXML.@op, null);
			if(s) op = s;
			
			s = XMLUtilities.stringAttr(flowXML.@arg0, null);
			if(s) arg0 = new Expression(s);
			
			s = XMLUtilities.stringAttr(flowXML.@arg1, null);
			if(s) arg1 = new Expression(s);
			
			hidden = XMLUtilities.booleanAttr(flowXML.@hide, false);
			
			s = XMLUtilities.stringAttr(flowXML.@skin, null);
				
			if(s) try {
				sourceSkin = getClassByAlias(s);
			}
			catch (e:Error) {
				Alert.show(s, "Unrecognised skin", Alert.OK, flowGroup); 
			}
			
		}
	}
}