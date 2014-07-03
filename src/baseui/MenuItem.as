package baseui {

import flash.events.MouseEvent;

//  MenuItem
// 
public class MenuItem extends Control
{
  public var value:Object;

  public override function toString():String
  {
    return ("<MenuItem "+value+">");
  }

  protected override function onMouseOver(e:MouseEvent):void 
  {
    super.onMouseOver(e);
    dispatchEvent(new MenuItemEvent(this));
  }

  protected override function onMouseOut(e:MouseEvent):void 
  {
    super.onMouseOut(e);
    dispatchEvent(new MenuItemEvent(null));
  }
}

} // package
