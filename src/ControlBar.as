package {

import flash.display.Sprite;
import flash.utils.getTimer;
import baseui.Style;
import baseui.PopupMenuButton;

//  ControlBar
//  Bar shown at the bottom of screen containing buttons, etc.
//
public class ControlBar extends Sprite
{
  public var margin:int = 4;
  public var fadeDuration:int = 1000;

  public var playButton:PlayPauseButton;
  public var volumeSlider:VolumeSlider;
  public var seekBar:SeekBar;
  public var statusDisplay:StatusDisplay;
  public var popupMenu:PopupMenuButton;
  public var fsButton:FullscreenButton;

  private var _autohide:Boolean;
  private var _timeout:int;

  public function ControlBar(fullscreen:Boolean=false, 
			     menu:Boolean=false)
  {
    super();
    _timeout = -fadeDuration;

    playButton = new PlayPauseButton();
    addChild(playButton);

    volumeSlider = new VolumeSlider();
    volumeSlider.value = 1.0;
    addChild(volumeSlider);

    seekBar = new SeekBar();
    seekBar.visible = false;
    addChild(seekBar);

    statusDisplay = new StatusDisplay();
    addChild(statusDisplay);

    if (menu) {
      popupMenu = new PopupMenuButtonOfDoom();
      addChild(popupMenu);
    }
    
    if (fullscreen) {
      fsButton = new FullscreenButton();
      addChild(fsButton);
    }
  }
  
  public function get autohide():Boolean
  {
    return _autohide;
  }

  public function set autohide(value:Boolean):void
  {
    _autohide = value;
  }

  public function set style(value:Style):void
  {
    playButton.style = value;
    volumeSlider.style = value;
    seekBar.style = value;
    statusDisplay.style = value;
    if (popupMenu != null) {
      popupMenu.style = value;
    }
    if (fsButton != null) {
      fsButton.style = value;
    }
  }

  public function show(duration:int=2000):void
  {
    _timeout = getTimer()+duration;
  }

  public function resize(w:int, h:int):void
  {
    var size:int = h - margin*2;
    var x0:int = margin;
    var x1:int = w - margin;

    graphics.clear();
    graphics.beginFill(0, 0.5);
    graphics.drawRect(0, 0, w, h);
    graphics.endFill();

    playButton.resize(size, size);
    playButton.x = x0;
    playButton.y = margin;
    x0 += playButton.width + margin;

    if (fsButton != null) {
      fsButton.resize(size, size);
      fsButton.x = x1 - fsButton.width;
      fsButton.y = margin;
      x1 = fsButton.x - margin;
    }
    
    if (popupMenu != null) {
      popupMenu.resize(size, size);
      popupMenu.x = x1 - popupMenu.width;
      popupMenu.y = margin;
      x1 = popupMenu.x - margin;
    }
    
    volumeSlider.resize(size*2, size);
    volumeSlider.x = x1 - volumeSlider.width;
    volumeSlider.y = margin;
    x1 = volumeSlider.x - margin;
    
    seekBar.resize(x1-x0, size);
    seekBar.x = x0;
    seekBar.y = margin;

    statusDisplay.resize(x1-x0, size);
    statusDisplay.x = x0;
    statusDisplay.y = margin;
  }

  public function update():void
  {
    if (_autohide) {
      var a:Number = (_timeout - getTimer())/fadeDuration + 1.0;
      alpha = Math.min(Math.max(a, 0.0), 1.0);
    } else {
      alpha = 1.0;
    }
    playButton.update();
    volumeSlider.update();
    seekBar.update();
    statusDisplay.update();
    if (popupMenu != null) {
      popupMenu.update();
    }
    if (fsButton != null) {
      fsButton.update();
    }
  }
}

} // package

import baseui.PopupMenuButton;

class PopupMenuButtonOfDoom extends PopupMenuButton
{
  public override function repaint():void
  {
    super.repaint();
    
    // draw a gear.
    var size:int = buttonSize/8;
    var color:uint = (highlit)? style.hiFgColor : style.fgColor;
    var cx:int = width/2 + ((pressed)? 1 : 0);
    var cy:int = height/2 + ((pressed)? 1 : 0);

    graphics.beginFill(color, (color>>>24)/255);
    graphics.moveTo(cx+size*3, cy);
    const T:Number = 2.0*Math.PI/32;
    for (var i:int = 0; i < 32; i++) {
      var r:Number = ((i % 4) < 2)? 3 : 2;
      graphics.lineTo(cx+Math.cos(T*i)*size*r, cy+Math.sin(T*i)*size*r);
    }
    graphics.lineTo(cx+size*3, cy);
    graphics.drawCircle(cx, cy, size*1);
    graphics.endFill();
  }
}
