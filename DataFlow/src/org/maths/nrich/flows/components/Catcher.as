package org.maths.nrich.flows.components
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.graphics.SolidColor;
	import mx.graphics.SolidColorStroke;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IStyleManager2;
	import mx.styles.StyleManager;
	
	import org.maths.Complex;
	import org.maths.Expression;
	import org.maths.nrich.flows.interfaces.IDropZone;
	import org.maths.nrich.flows.interfaces.IOp;
	import org.maths.nrich.flows.interfaces.IPad;
	import org.maths.nrich.flows.model.vo.InPad;
	import org.maths.nrich.flows.model.vo.Mapping;
	import org.maths.nrich.flows.skins.parts.DropPad;
	
	import spark.components.Group;
	import spark.components.RichEditableText;
	import spark.components.supportClasses.SkinnableComponent;
	
	public class Catcher extends SkinnableComponent implements IDropZone
	{
		
		public function Catcher()
		{
			setupStyles();
			super();
			this.addEventListener(Event.ADDED_TO_STAGE, addStageHandlers);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removeStageHandlers);
		}
				
		//public var flowGroup:FlowGroup;
		
		
		public function get flowGroup():FlowGroup 
		{
			return parentFlow.flowGroup;
		}
		
		private var _arg0:Expression;
		[Bindable]
		public function get arg0():Expression
		{
			return _arg0;
		}
		public function set arg0(s:Expression):void
		{
			_arg0 = s;

//			if(parentFlow.isInput)
//				flowGroup.newInputValue(parentFlow as InputFlow);
			
			if(parentFlow.isOutput)
				(parentFlow as OutputFlow).complete();
			
			invalidateProperties();
		}
		
		private var _arg1:Expression;
		[Bindable]
		public function get arg1():Expression
		{
			return _arg1;
		}
		public function set arg1(s:Expression):void
		{
			_arg1 = s;
			invalidateProperties();
		}
		
		public function get ioPadColour():SolidColor 
		{
			return flowGroup.ioPadColour;
		}
		
		[Bindable]
		public var op:String;
		
		[SkinPart(required="true")]
		public var source:Group;
		
		[SkinPart(required="true")]
		public var sourceArea:Group;
		
		[SkinPart(required="true")]
		public var padWrapper:Group;
		
		[SkinPart(required="false")]
		public var dragSpot:DragSpot;
		
		[SkinPart(required="false")]
		public var pad0:IPad;
		
		[SkinPart(required="false")]
		public var opView:IOp;
		
		[SkinPart(required="false")]
		public var pad1:IPad;
		
		[SkinPart(required="false")]
		public var inPad:InPad;
		
		[SkinPart(required="false")]
		public var variable:RichEditableText;
		
			
		private function addStageHandlers(event:Event):void {				
			stage.addEventListener(MouseEvent.MOUSE_UP, stageMouseUp);			
		}
		
		private function removeStageHandlers(event:Event):void {
			
			removeEventListener(Event.REMOVED_FROM_STAGE, removeStageHandlers);
			removeEventListener(Event.ADDED_TO_STAGE, addStageHandlers);
			
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragging);
			
		}
		
		private var _showValues:int = 0;
		public function get showValues():int
		{
			return _showValues;
		}
		public function set showValues(value:int):void
		{
			_showValues = value;
			invalidateProperties();
		}
		
		private var dragging:Boolean = false;
		private var sx0:int;
		private var sy0:int;
		
		private function stageMouseUp(event:MouseEvent):void {
			if(dragging) {
				stopDragging(event);
			}
		}
		
		protected function startDragging(event:MouseEvent):void {
			if(!dragging) {
				var dragBounds: Rectangle;
				
				dragBounds = flowGroup.getRect(parentFlow.skin);
				dragBounds.width -= width;
				dragBounds.height -= height;
				sx0 = x;
				sy0 = y;

//				trace("x,y="+x+","+y+" bounds="+dragBounds.left+","+dragBounds.top+" "+dragBounds.right+","+dragBounds.bottom);
				
				dragging = true;
				startDrag(false, dragBounds);
				
				stage.addEventListener(MouseEvent.MOUSE_MOVE, sourceMove);
			}
		}
		
		private function stopDragging(event:MouseEvent = null):void {
			if(dragging) {
				dragging = false;
				stopDrag();
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, sourceMove);
			}
		}
		
				
		override protected function partAdded(partName:String, instance:Object):void { 
			super.partAdded(partName, instance);
			
			if(instance == sourceArea) {
				//trace("Catcher sourceArea added");
				sourceArea.addEventListener(MouseEvent.MOUSE_DOWN, startDragging);
				sourceArea.addEventListener(MouseEvent.MOUSE_UP, stopDragging);
			}
			else if(instance == dragSpot) {
				dragSpot.addEventListener(MouseEvent.MOUSE_DOWN, addSink);
			}
			else if(instance == pad0) {
				pad0.addEventListener(DropPad.PADEDIT, pad0Edit);
			}			
			else if(instance == pad1) {
				pad1.addEventListener(DropPad.PADEDIT, pad1Edit);
			}
			else if(instance == inPad) {
				if(parentFlow.arg0) {
					var z:Complex = parentFlow.arg0.evaluate();
					inPad.exprAsNumber = 0;
					if(z)
						inPad.exprAsNumber = z.x;
				}
				else
					parentFlow.arg0 = inPad.expression;
				inPad.addEventListener(InPad.CHANGE, inPadEdit);
			}
			else if(instance == opView) {
				opView.opText = op;
				//invalidateDisplayList();
			}
			else if(instance == variable) {
				//trace("variable added")
				variable.addEventListener(Event.CHANGE, variableChanged);
			}
		}
		
		override protected function partRemoved(partName:String, instance:Object) : void
		{
			if(instance == sourceArea) {
				//trace("Catcher sourceArea removed");
				sourceArea.removeEventListener(MouseEvent.MOUSE_DOWN, startDragging);
				sourceArea.removeEventListener(MouseEvent.MOUSE_UP, stopDragging);
			}
			else if(instance == dragSpot) {
				dragSpot.removeEventListener(MouseEvent.MOUSE_DOWN, addSink);
			}
			else if(instance == "pad1") {
				hasFocusableChildren = false;
			}
			else if(instance == variable) {
				//trace("variable removed")
				variable.removeEventListener(Event.CHANGE, variableChanged);
			}
		}
				
		private function pad0Edit(event:Event):void {
			parentFlow.arg0 = pad0.expression;
		}
		
		private function inPadEdit(event:Event):void {
			parentFlow.arg0 = inPad.expression;
		}
		
		private function pad1Edit(event:Event):void {
			parentFlow.arg1 = pad1.expression;
		}
		
		private function variableChanged(event:Event):void
		{
			var map:Mapping = parentFlow.flowMap;
			if(map) {
				map.renameVariables();//parentFlow as InputFlow, event.oldName, event.newName);
			}
		}
		
		
 //-------------- Sink management ------------
		
		public function get parentFlow():Flow
		{
			var p:DisplayObjectContainer = parent;
			while(p && !(p is Flow))
				p = p.parent;
			return p as Flow;	
		}
		
		
		private function addSink(event:MouseEvent):void {
			parentFlow.addSink();
		}
		
		private function sourceMove(event:MouseEvent):void {
			parentFlow.updateAllPaths();
		}

		override protected function commitProperties() : void
		{
			super.commitProperties();

			if(opView)
				opView.opText = op;
			
			parentFlow.updateAllPaths();
			parentFlow.updateDecorator();

			if(pad0 != null)
				pad0.showValues = showValues;
			if(pad1 != null)
				pad1.showValues = showValues;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number) : void 
		{
			parentFlow.updateAllPaths();			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}

//-------------- Style management ----------------
		
		
		[Bindable]
		public var fontSize:int;
		
		[Bindable]
		public var sourceFill:SolidColor;
		
		[Bindable]
		public var flowColour:SolidColor;
		
		[Bindable]
		public var flowStroke:SolidColorStroke;
		
		[Bindable]
		public var numberPadColour:SolidColor;
		

		private function setupStyles():void {
			var sm:IStyleManager2 = StyleManager.getStyleManager(null);
			var flowStyle:CSSStyleDeclaration = sm.getStyleDeclaration(".flow"); //StyleManager.getStyleDeclaration(".flow");
			var s:String = flowStyle.getStyle('numberPadFill');
			numberPadColour = new SolidColor(Number(s) || 0xdddddd);
			fontSize = int(flowStyle.getStyle('fontSize')) || 24;
			var flowColourValue:int = flowStyle.getStyle('flowColour') || 0xccccff;
			flowColour = new SolidColor(flowColourValue);
			flowStroke = new SolidColorStroke(
				flowColourValue,
				Number(flowStyle.getStyle('flowWeight')) || 4
			);
			sourceFill = new SolidColor(0x999999);
		}	
	}
}