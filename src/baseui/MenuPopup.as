package baseui {

import flash.events.MouseEvent;

//  MenuPopup
//
public class MenuPopup extends Button
{
  public var margin:int = 2;

  private var _totalWidth:int;
  private var _totalHeight:int;
  private var _needResize:Boolean;
  private var _items:Vector.<MenuItem>;
  private var _chosen:MenuItem;

  public function MenuPopup()
  {
    super();
    _items = new Vector.<MenuItem>();
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
    item.style = style;
    item.addEventListener(MenuItemEvent.CHOOSE, onItemChosen);
    addChild(item);
    _items.push(item);
    _needResize = true;
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

  private function updateSize():void
  {
    var item:MenuItem;
    _totalWidth = 0;
    _totalHeight = 0;
    for each (item in _items) {
      item.x = margin;
      item.y = margin+_totalHeight;
      _totalWidth = Math.max(_totalWidth, item.controlWidth);
      _totalHeight += item.controlHeight;
    }
    for each (item in _items) {
      item.resize(_totalWidth, item.controlHeight);
    }
    resize(_totalWidth+margin*2, _totalHeight+margin*2);
    _needResize = false;
  }

  public override function update():void
  {
    super.update();
    if (_needResize) {
      updateSize();
    }
    for each (var item:MenuItem in _items) {
      item.update();
    }
  }
}

} // package
