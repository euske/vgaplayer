package baseui {

import flash.display.DisplayObjectContainer;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.utils.getTimer;

//  PopupMenuButton
//
public class PopupMenuButton extends Button
{
  public var minDuration:int = 100;

  private var _popup:MenuPopup;
  private var _container:DisplayObjectContainer;
  private var _timeout:int;

  public function PopupMenuButton()
  {
    super();
    _popup = new MenuPopup();
    _popup.addEventListener(MenuItemEvent.CHOOSE, onItemChosen);
  }

  public override function set style(value:Style):void
  {
    super.style = value;
    _popup.style = value;
  }

  public function set container(value:DisplayObjectContainer):void
  {
    _container = value;
  }

  public function addTextItem(label:String, value:Object=null):MenuItem
  {
    return _popup.addTextItem(label, value);
  }

  public function addItem(item:MenuItem):MenuItem
  {
    return _popup.addItem(item);
  }
  
  protected virtual function onItemChosen(e:MenuItemEvent):void 
  {
    dispatchEvent(new MenuItemEvent(e.item));
    if (_popup.parent != null) {
      _popup.parent.removeChild(_popup);
    }
  }

  protected override function onMouseDownLocal(e:MouseEvent):void 
  {
    super.onMouseDownLocal(e);
    if (_popup.parent != null) {
      // The menu is still open.
      _popup.parent.removeChild(_popup);
    } else {
      var container:DisplayObjectContainer = (_container != null)? _container : parent;
      var p:Point = container.globalToLocal(new Point(e.stageX, e.stageY));
      _popup.x = p.x;
      if (container.width < _popup.x+_popup.width) {
	_popup.x -= _popup.width;
      }
      _popup.y = p.y;
      if (container.height < _popup.y+_popup.height) {
	_popup.y -= _popup.height;
      }
      container.addChild(_popup);
      _timeout = getTimer() + minDuration;
    }
  }

  protected override function onMouseUpLocal(e:MouseEvent):void 
  {
    super.onMouseUpLocal(e);
    if (_popup.parent != null) {
      if (_timeout < getTimer()) {
	_popup.parent.removeChild(_popup);
      }
    }
  }

  public override function update():void
  {
    super.update();
    if (_popup.parent != null) {
      _popup.update();
    }
  }
}

} // package
