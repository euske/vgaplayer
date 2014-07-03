package {

import baseui.Button;

//  PlayPauseButton
//  Play/pause toggle button. (part of ControlBar)
//
public class PlayPauseButton extends Button
{
  private var _toPlay:Boolean = false;

  public function get toPlay():Boolean
  {
    return _toPlay;
  }

  public function set toPlay(value:Boolean):void
  {
    _toPlay = value;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = buttonSize/16;
    var color:uint = (highlit)? style.hiFgColor : style.fgColor;
    var cx:int = width/2 + ((pressed)? 1 : 0);
    var cy:int = height/2 + ((pressed)? 1 : 0);

    if (_toPlay) {
      graphics.beginFill(color, (color>>>24)/255);
      graphics.moveTo(cx-size*3, cy-size*4);
      graphics.lineTo(cx-size*3, cy+size*4);
      graphics.lineTo(cx+size*4, cy);
      graphics.endFill();
    } else {
      graphics.beginFill(color, (color>>>24)/255);
      graphics.drawRect(cx-size*3, cy-size*4, size*2, size*8);
      graphics.drawRect(cx+size*1, cy-size*4, size*2, size*8);
      graphics.endFill();
    }
  }
}

} // package
