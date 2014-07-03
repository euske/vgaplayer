package baseui {

import flash.events.Event;

//  MenuItemEvent
//
public class MenuItemEvent extends Event
{
  public static const CHOOSE:String = "MenuItemEvent.CHOOSE";

  public var item:MenuItem;

  public function MenuItemEvent(item:MenuItem=null)
  {
    super(CHOOSE);
    this.item = item;
  }
}

} // package
