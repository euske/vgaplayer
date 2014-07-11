package baseui {

//  Button
//  Generic button class.
//  
public class Button extends Control
{
  public function get buttonSize():int
  {
    return Math.min(controlWidth, controlHeight);
  }

  public override function repaint():void
  {
    super.repaint();

    if (highlit) {
      graphics.lineStyle(0, style.borderColor, (style.borderColor>>>24)/255);
      graphics.drawRect(0, 0, controlWidth, controlHeight);
    }
  }
}

} // package
