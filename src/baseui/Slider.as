package baseui {

import flash.events.Event;
import flash.events.MouseEvent;

//  Slider
//  Generic slider class.
// 
public class Slider extends Button
{
  public static const CLICK:String = "Slider.Click";
  public static const CHANGED:String = "Slider.Changed";

  public var minDelta:int = 4;

  private var _x0:int;
  private var _y0:int;
  private var _changing:Boolean;

  protected override function onMouseDownLocal(e:MouseEvent):void 
  {
    super.onMouseDownLocal(e);
    addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    _x0 = e.localX;
    _y0 = e.localY;
    _changing = false;
  }

  protected override function onMouseUpLocal(e:MouseEvent):void 
  {
    if (!_changing && pressed) {
      dispatchEvent(new Event(CLICK));
    }
    removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    super.onMouseUpLocal(e);
  }

  protected virtual function onMouseMove(e:MouseEvent):void 
  {
    if (_changing) {
      onMouseDrag(e);
    } else {
      if (minDelta <= Math.abs(e.localX-_x0) ||
	  minDelta <= Math.abs(e.localY-_y0)) {
	_changing = true;
      }
    }
  }

  protected virtual function onMouseDrag(e:MouseEvent):void
  {
  }
}

} // package
