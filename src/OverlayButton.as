package {

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.utils.getTimer;
import baseui.Style;

//  OverlayButton
//  A transparent button shown over the video.
//
public class OverlayButton extends Sprite
{
  public const PLAY:String = "PLAY";
  public const PAUSE:String = "PAUSE";
  public const BUSY:String = "BUSY";

  public var style:Style = new Style();
  public var buttonSize:int = 100;
  public var fadeDuration:int = 2000;
  
  private var _size:int;
  private var _width:int;
  private var _height:int;
  private var _invalidated:Boolean;
  private var _highlit:Boolean;
  private var _state:String;
  private var _autohide:Boolean;
  private var _timeout:int;

  public function OverlayButton()
  {
    super();
    _timeout = 0;
    alpha = 0;
    addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
    addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
    addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
  }

  public function get state():String
  {
    return _state;
  }

  public function set state(value:String):void
  {
    _state = value;
    _invalidated = true;
  }

  public function get autohide():Boolean
  {
    return _autohide;
  }

  public function set autohide(value:Boolean):void
  {
    _autohide = value;
  }

  protected virtual function onMouseOver(e:MouseEvent):void 
  {
    _highlit = true;
    _invalidated = true;
  }

  protected virtual function onMouseOut(e:MouseEvent):void 
  {
    _highlit = false;
    _invalidated = true;
  }

  protected virtual function onMouseMove(e:MouseEvent):void 
  {
    if (_timeout < getTimer()) {
      show();
    }
  }

  public function resize(w:int, h:int):void
  {
    _width = w;
    _height = h;
    _invalidated = true;
  }
  
  public function show():void
  {
    _timeout = getTimer()+fadeDuration;
    _invalidated = true;
  }

  public function repaint():void
  {
    graphics.clear();
    graphics.beginFill(0, 0);
    graphics.drawRect(0, 0, _width, _height);
    graphics.endFill();

    var size:int = buttonSize/16;
    var cx:int = width/2;
    var cy:int = height/2;

    var fgcolor:uint = (_highlit)? style.hiFgColor : style.fgColor;
    var bgcolor:uint = (_highlit)? style.hiBgColor : style.bgColor;
    graphics.beginFill(bgcolor, (bgcolor>>>24)/255);
    graphics.drawRect(cx-buttonSize/2, cy-buttonSize/2, buttonSize, buttonSize);
    graphics.endFill();

    switch (_state) {
    case PLAY:
      graphics.beginFill(fgcolor, (fgcolor>>>24)/255);
      graphics.moveTo(cx-size*3, cy-size*4);
      graphics.lineTo(cx-size*3, cy+size*4);
      graphics.lineTo(cx+size*4, cy);
      graphics.endFill();
      break;
    case PAUSE:
      graphics.beginFill(fgcolor, (fgcolor>>>24)/255);
      graphics.drawRect(cx-size*3, cy-size*4, size*2, size*8);
      graphics.drawRect(cx+size*1, cy-size*4, size*2, size*8);
      graphics.endFill();
      break;
    case BUSY:
      graphics.beginFill(fgcolor, (fgcolor>>>24)/255);
      graphics.drawCircle(cx-size*3, cy, size);
      graphics.drawCircle(cx, cy, size);
      graphics.drawCircle(cx+size*3, cy, size);
      graphics.endFill();
      break;
    }
  }
  
  public function update():void
  {
    if (_invalidated) {
      _invalidated = false;
      repaint();
    }

    if (_autohide) {
      var a:Number = (_timeout - getTimer())/fadeDuration;
      alpha = Math.min(Math.max(a, 0.0), 1.0);
    } else {
      alpha = 1.0;
    }
  }
}

} // package
