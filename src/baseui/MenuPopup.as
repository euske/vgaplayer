package baseui {

import flash.events.MouseEvent;

//  MenuPopup
//
public class MenuPopup extends Control
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
    item.style = style;
    item.x = margin;
    item.y = margin+_totalHeight;
    item.addEventListener(MenuItemEvent.CHOOSE, onItemChosen);
    addChild(item);
    _items.push(item);
    _totalWidth = Math.max(_totalWidth, item.width);
    _totalHeight += item.height;
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

  public override function repaint():void
  {
    var w:int = _totalWidth+margin*2;
    var h:int = _totalHeight+margin*2;
    graphics.clear();
    graphics.beginFill(style.hiBgColor, (style.hiBgColor>>>24)/255);
    graphics.drawRect(0, 0, w, h);
    graphics.endFill();

    if (highlit) {
      graphics.lineStyle(0, style.borderColor, (style.borderColor>>>24)/255);
      graphics.drawRect(0, 0, w, h);
    }
  }
}

} // package
