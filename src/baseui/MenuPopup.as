package baseui {

import flash.events.MouseEvent;

//  MenuPopup
//
public class MenuPopup extends Button
{
  public var margin:int = 2;

  private var _totalWidth:int;
  private var _totalHeight:int;
  private var _items:Array;
  private var _chosen:MenuItem;

  public function MenuPopup()
  {
    super();
    _items = new Array();
    _totalWidth = 0;
    _totalHeight = 0;
  }

  public override function set style(value:Style):void
  {
    super.style = value;
    for each (var item:MenuItem in _items) {
      item.style = value;
    }
  }

  public function get chosen():MenuItem
  {
    return _chosen;
  }

  public function addTextItem(label:String, value:Object=null):MenuItem
  {
    var item:TextMenuItem = new TextMenuItem();
    item.label = label;
    item.value = (value != null)? value : label;
    return addItem(item);
  }

  public function addItem(item:MenuItem):MenuItem
  {
    _items.push(item);
    _totalWidth = Math.max(_totalWidth, item.width);
    _totalHeight += item.height;
    item.style = style;
    item.x = margin;
    item.y = height;
    item.addEventListener(MenuItemEvent.CHOOSE, onItemChosen);
    addChild(item);
    resize(_totalWidth+margin*2, _totalHeight+margin*2);
    return item;
  }

  protected override function onMouseUp(e:MouseEvent):void 
  {
    super.onMouseUp(e);
    if (_chosen != null) {
      dispatchEvent(new MenuItemEvent(_chosen));
      _chosen = null;
    }
  }

  private function onItemChosen(e:MenuItemEvent):void
  {
    if (e.item != null) {
      _chosen = e.item;
    } else if (e.target == _chosen) {
      _chosen = null;
    }
  }

  public override function update():void
  {
    super.update();
    for each (var item:MenuItem in _items) {
      item.update();
    }
  }
}

} // package
