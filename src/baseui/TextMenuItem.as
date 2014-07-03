package baseui {

import flash.text.TextField;
import flash.text.TextFieldAutoSize;

//  TextMenuItem
// 
public class TextMenuItem extends MenuItem
{
  private var _text:TextField;

  public function TextMenuItem()
  {
    super();
    _text = new TextField();
    _text.selectable = false;
    _text.background = true;
    _text.autoSize = TextFieldAutoSize.LEFT;
    addChild(_text);
  }

  public function get label():String
  {
    return _text.text;
  }

  public function set label(v:String):void
  {
    _text.text = v;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();

    _text.backgroundColor = (highlit)? style.bgColor : style.hiBgColor;
    _text.textColor = (highlit)? style.hiFgColor : style.fgColor;
  }
}

} // package
