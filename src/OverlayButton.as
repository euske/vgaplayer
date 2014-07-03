package {

import flash.display.Sprite;
import flash.utils.getTimer;
import baseui.Style;

//  OverlayButton
//  A transparent button shown over the video.
//
public class OverlayButton extends Sprite
{
  public var style:Style = new Style();
  public var buttonSize:int = 100;
  public var fadeDuration:int = 2000;

  private var _size:int;
  private var _width:int;
  private var _height:int;
  private var _invalidated:Boolean;
  private var _toPlay:Boolean;
  private var _autohide:Boolean;
  private var _timeout:int;

  public function OverlayButton()
  {
    super();
    _timeout = -fadeDuration;
    alpha = 0;
  }

  public function get toPlay():Boolean
  {
    return _toPlay;
  }

  public function set toPlay(value:Boolean):void
  {
    _toPlay = value;
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

  public function resize(w:int, h:int):void
  {
    _width = w;
    _height = h;
    _invalidated = true;
  }
  
  public function show():void
  {
    _timeout = getTimer();
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

    graphics.beginFill(style.bgColor, (style.bgColor>>>24)/255);
    graphics.drawRect(cx-buttonSize/2, cy-buttonSize/2, buttonSize, buttonSize);
    graphics.endFill();
    if (_toPlay) {
      graphics.beginFill(style.fgColor, (style.fgColor>>>24)/255);
      graphics.moveTo(cx-size*3, cy-size*4);
      graphics.lineTo(cx-size*3, cy+size*4);
      graphics.lineTo(cx+size*4, cy);
      graphics.endFill();
    } else {
      graphics.beginFill(style.fgColor, (style.fgColor>>>24)/255);
      graphics.drawRect(cx-size*3, cy-size*4, size*2, size*8);
      graphics.drawRect(cx+size*1, cy-size*4, size*2, size*8);
      graphics.endFill();
    }
  }
  
  public function update():void
  {
    if (_invalidated) {
      _invalidated = false;
      repaint();
    }

    if (_autohide) {
      var a:Number = (_timeout - getTimer())/fadeDuration + 1.0;
      alpha = Math.min(Math.max(a, 0.0), 1.0);
    } else {
      alpha = 1.0;
    }
  }
}

} // package
