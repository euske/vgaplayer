package {

import baseui.Button;

//  FullscreenButton
//  Fullscreen/Windowed toggle button. (part of ControlBar)
//
public class FullscreenButton extends Button
{
  private var _toFullscreen:Boolean = false;

  public function get toFullscreen():Boolean
  {
    return _toFullscreen;
  }

  public function set toFullscreen(value:Boolean):void
  {
    _toFullscreen = value;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = buttonSize/16;
    var color:uint = (highlit)? style.hiFgColor : style.fgColor;
    var cx:int = width/2 + ((pressed)? 1 : 0);
    var cy:int = height/2 + ((pressed)? 1 : 0);

    if (_toFullscreen) {
      graphics.beginFill(color, (color>>>24)/255);
      graphics.drawRect(cx-size*7, cy-size*4, size*14, size*8);
      graphics.endFill();
    } else {
      graphics.lineStyle(0, color, (color>>>24)/255);
      graphics.drawRect(cx-size*7, cy-size*5, size*10, size*6);
      graphics.drawRect(cx-size*2, cy-size*1, size*9, size*7);
    }
  }
}

} // package
