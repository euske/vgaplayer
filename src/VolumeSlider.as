package {

import flash.events.Event;
import flash.events.MouseEvent;
import baseui.Slider;

//  VolumeSlider
//  A volume slider.  (part of ControlBar)
//
public class VolumeSlider extends Slider
{
  public var muteColor:uint = 0xffff0000;

  private var _value:Number = 0;
  private var _muted:Boolean = false;
  
  protected override function onMouseDrag(e:MouseEvent):void 
  {
    super.onMouseDrag(e);
    var size:int = buttonSize/8;
    var w:int = (width-size*2);
    value = (e.localX-size)/w;
    dispatchEvent(new Event(CHANGED));
  }

  public function get value():Number
  {
    return _value;
  }

  public function set value(v:Number):void
  {
    v = Math.max(0, Math.min(1, v));
    if (_value != v) {
      _value = v;
      invalidate();
    }
  }

  public function get muted():Boolean
  {
    return _muted;
  }

  public function set muted(value:Boolean):void
  {
    _muted = value;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = buttonSize/4;
    var color:uint = (highlit)? style.hiColor : style.fgColor;
    var cx:int = width/2;
    var cy:int = height/2;

    graphics.lineStyle(0, color, (color>>>24)/255);
    graphics.moveTo(size, height-size);
    graphics.lineTo(width-size, size);
    graphics.lineTo(width-size, height-size);
    graphics.lineTo(size, height-size);

    var w:int = (width-size*2);
    var h:int = (height-size*2);
    graphics.beginFill(color, (color>>>24)/255);
    graphics.moveTo(size, height-size);
    graphics.lineTo(size+_value*w, height-size-_value*h);
    graphics.lineTo(size+_value*w, height-size);
    graphics.endFill();

    if (_muted) {
      graphics.lineStyle(2, muteColor, (muteColor>>>24)/255);
      graphics.moveTo(cx-size, cy-size);
      graphics.lineTo(cx+size, cy+size);
    }
  }
}

} // package
