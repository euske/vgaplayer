package {

import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.events.Event;
import flash.events.MouseEvent;
import baseui.Slider;

//  SeekBar
//  A horizontal seek bar.  (part of ControlBar)
//
public class SeekBar extends Slider
{
  public var margin:int = 4;
  public var barSize:int = 2;

  private var _text:TextField;
  private var _duration:Number = 0;
  private var _bytesTotal:uint = 0;
  private var _bytesLoaded:uint = 0;
  private var _static:Boolean = false;
  private var _locked:Boolean = false;
  private var _time:Number = 0;
  private var _goal:Number = 0;

  public function SeekBar()
  {
    super();
    _text = new TextField();
    _text.x = margin;
    _text.selectable = false;
    _text.autoSize = TextFieldAutoSize.LEFT;
    addChild(_text);
  }

  public function setTextFormat(textFormat:TextFormat, embedFonts:Boolean=false):void
  {
    _text.defaultTextFormat = textFormat;
    _text.embedFonts = embedFonts;
    invalidate();
  }
  
  protected override function onMouseDownLocal(e:MouseEvent):void 
  {
    super.onMouseDownLocal(e);
    updateGoal(e.localX);
  }

  protected override function onMouseDrag(e:MouseEvent):void 
  {
    super.onMouseDrag(e);
    updateGoal(e.localX);
  }

  protected override function onMouseUpLocal(e:MouseEvent):void 
  {
    super.onMouseUpLocal(e);
    dispatchEvent(new Event(CHANGED));
  }

  private function updateGoal(x:int):void
  {
    var w:int = (width-margin-leftMargin);
    var v:Number = (x-leftMargin)/w;
    v = Math.min(v, availableRatio);
    _locked = true;
    _goal = Math.max(0, Math.min(1, v)) * _duration;
    invalidate();
  }

  public function get leftMargin():int
  {
    return (margin+_text.width);
  }

  public function get duration():Number
  {
    return _duration;
  }

  public function set duration(v:Number):void
  {
    _duration = v;
    invalidate();
  }

  public function set isStatic(v:Boolean):void
  {
    _static = v;
    invalidate();
  }

  public function set bytesTotal(v:uint):void
  {
    _bytesTotal = v;
    invalidate();
  }

  public function set bytesLoaded(v:uint):void
  {
    _bytesLoaded = v;
    invalidate();
  }

  public function get availableRatio():Number
  {
    if (_static && 0 < _bytesTotal) {
      return _bytesLoaded / Number(_bytesTotal);
    } else {
      return 1.0;
    }
  }

  public function set time(v:Number):void
  {
    _time = v;
    invalidate();
  }

  public function get time():Number
  {
    return (_locked)? _goal : _time;
  }

  public function unlock():void
  {
    _locked = false;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = barSize;
    var color:uint = (highlit)? style.hiFgColor : style.fgColor;
    var t:Number = (_locked)? _goal : _time;

    _text.text = (Math.floor(t/3600)+":"+
		  format2(Math.floor(t/60)%60, "0")+":"+
		  format2(t%60, "0")+" ");
    _text.textColor = color;

    var w:int = (width-margin-leftMargin);
    var h:int = (height-margin*2);
    graphics.beginFill(color, (color>>>24)/255);
    graphics.drawRect(leftMargin, (height-size)/2, w*availableRatio, size);
    if (0 < _duration) {
      graphics.drawRect(leftMargin+w*t/_duration-size, margin, size*2, h);
    }
    graphics.endFill();
  }

  private function format2(v:int, c:String=" "):String
  {
    return ((v < 10)? c+v : String(v));
  }
}

} // package
