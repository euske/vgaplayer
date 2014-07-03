package {

import baseui.Control;
import flash.text.TextField;
import flash.text.TextFormat;

//  StatusDisplay
//  Shows a text status. (part of ControlBar)
//
public class StatusDisplay extends Control
{
  private var _text:TextField;

  public function StatusDisplay()
  {
    super();
    _text = new TextField();
    _text.selectable = false;
    addChild(_text);
  }

  public function setTextFormat(textFormat:TextFormat, embedFonts:Boolean=false):void
  {
    _text.defaultTextFormat = textFormat;
    _text.embedFonts = embedFonts;
    invalidate();
  }
  
  public function get text():String
  {
    return _text.text;
  }
  public function set text(value:String):void
  {
    _text.text = value;
  }

  public override function resize(w:int, h:int):void
  {
    super.resize(w, h);
    _text.width = w;
    _text.height = h;
  }

  public override function repaint():void
  {
    super.repaint();
    var color:uint = (highlit)? style.hiColor : style.fgColor;
    _text.textColor = color;
  }
}

} // package
