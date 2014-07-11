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
    resize(_text.width, _text.height);
  }

  public override function repaint():void
  {
    //super.repaint();

    graphics.clear();
    if (highlit) {
      graphics.beginFill(style.hiFgColor);
    } else {
      graphics.beginFill(0, 0);
    }
    graphics.drawRect(0, 0, controlWidth, controlHeight);
    graphics.endFill();

    _text.x = (highlit)? 1 : 0;
    _text.y = (highlit)? 1 : 0;
    _text.textColor = (highlit)? style.hiBgColor : style.fgColor;
  }
}

} // package
