package {

import baseui.Button;

//  PlayPauseButton
//  Play/pause toggle button. (part of ControlBar)
//
public class PlayPauseButton extends Button
{
  public const PLAY:String = "PLAY";
  public const PAUSE:String = "PAUSE";
  public const BUSY:String = "BUSY";

  private var _state:String;

  public function get state():String
  {
    return _state;
  }

  public function set state(value:String):void
  {
    _state = value;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = buttonSize/16;
    var color:uint = (highlit)? style.hiFgColor : style.fgColor;
    var cx:int = width/2 + ((pressed)? 1 : 0);
    var cy:int = height/2 + ((pressed)? 1 : 0);

    switch (_state) {
    case PLAY:
      graphics.beginFill(color, (color>>>24)/255);
      graphics.moveTo(cx-size*3, cy-size*4);
      graphics.lineTo(cx-size*3, cy+size*4);
      graphics.lineTo(cx+size*4, cy);
      graphics.endFill();
      break;
    case PAUSE:
      graphics.beginFill(color, (color>>>24)/255);
      graphics.drawRect(cx-size*3, cy-size*4, size*2, size*8);
      graphics.drawRect(cx+size*1, cy-size*4, size*2, size*8);
      graphics.endFill();
      break;
    }
  }
}

} // package
