package baseui {

import flash.events.Event;
import flash.events.MouseEvent;
import flash.display.Sprite;

//  Control
//  Base class for buttons/sliders.
//
public class Control extends Sprite
{
  private var _style:Style = new Style();
  private var _width:int;
  private var _height:int;

  private var _mousedown:Boolean;
  private var _mouseover:Boolean;
  private var _invalidated:Boolean;

  public function Control()
  {
    super();
    addEventListener(Event.ADDED_TO_STAGE, onAdded);
    addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
    addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
  }

  public function get pressed():Boolean
  {
    return _mouseover && _mousedown;
  }

  public function get highlit():Boolean
  {
    return _mouseover || _mousedown;
  }
  
  private function onAdded(e:Event):void 
  {
    stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
  }

  public virtual function get style():Style
  {
    return _style;
  }

  public virtual function set style(value:Style):void
  {
    _style = value;
  }

  protected virtual function onMouseDown(e:MouseEvent):void 
  {
    if (_mouseover) {
      _mousedown = true;
      _invalidated = true;
      onMouseDownLocal(e);
    }
  }

  protected virtual function onMouseUp(e:MouseEvent):void 
  {
    if (_mousedown) {
      onMouseUpLocal(e);
      _mousedown = false;
      _invalidated = true;
    }
  }

  protected virtual function onMouseOver(e:MouseEvent):void 
  {
    _mouseover = true;
    _invalidated = true;
  }

  protected virtual function onMouseOut(e:MouseEvent):void 
  {
    _mouseover = false;
    _invalidated = true;
  }

  protected virtual function onMouseDownLocal(e:MouseEvent):void 
  {
  }

  protected virtual function onMouseUpLocal(e:MouseEvent):void 
  {
  }

  protected function invalidate():void
  {
    _invalidated = true;
  }

  public virtual function resize(w:int, h:int):void
  {
    _width = w;
    _height = h;
    repaint();
  }

  public virtual function repaint():void
  {
    graphics.clear();
    graphics.beginFill(style.bgColor, (style.bgColor>>>24)/255);
    graphics.drawRect(0, 0, _width, _height);
    graphics.endFill();
  }

  public virtual function update():void
  {
    if (_invalidated) {
      _invalidated = false;
      repaint();
    }
  }

}

} // package
