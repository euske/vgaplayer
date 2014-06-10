//  VGAPlayer
//

package {

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.display.StageAlign;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.FullScreenEvent;
import flash.events.NetStatusEvent;
import flash.events.AsyncErrorEvent;
import flash.media.Video;
import flash.media.SoundTransform;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.URLRequest;
import flash.ui.Keyboard;

//  Main 
//
public class Main extends Sprite
{
  private const STARTING:String = "STARTING";
  private const STARTED:String = "STARTED";
  private const STOPPING:String = "STOPPING";
  private const STOPPED:String = "STOPPED";
  
  private var _params:Params;
  private var _url:String;
  private var _video:Video;
  private var _overlay:OverlayButton;
  private var _control:ControlBar;
  private var _debugdisp:DebugDisplay;
  private var _imageLoader:Loader;

  private var _connection:NetConnection;
  private var _stream:NetStream;
  private var _videoMetaData:Object;
  private var _state:String;

  // Main()
  public function Main()
  {
    var info:LoaderInfo = LoaderInfo(this.root.loaderInfo);
    _params = new Params(info.parameters);
    _url = getBaseURL(_params.url);
    
    stage.color = _params.bgColor;
    stage.scaleMode = StageScaleMode.NO_SCALE;
    stage.align = StageAlign.TOP_LEFT;

    if (_params.imageUrl != null) {
      _imageLoader = new Loader();
      _imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
      _imageLoader.load(new URLRequest(_params.imageUrl));
      addChild(_imageLoader);
    }

    _video = new Video();
    _video.smoothing = _params.smoothing;
    addChild(_video);

    _overlay = new OverlayButton();
    _overlay.buttonBgColor = _params.buttonBgColor;
    _overlay.buttonFgColor = _params.buttonFgColor;
    _overlay.addEventListener(MouseEvent.CLICK, onOverlayClick);
    addChild(_overlay);

    _control = new ControlBar(_params.fullscreen);
    _control.statusDisplay.bgColor = _params.buttonBgColor;
    _control.statusDisplay.fgColor = _params.buttonFgColor;
    _control.statusDisplay.hiColor = _params.buttonHiColor;
    _control.playButton.bgColor = _params.buttonBgColor;
    _control.playButton.fgColor = _params.buttonFgColor;
    _control.playButton.hiColor = _params.buttonHiColor;
    _control.playButton.borderColor = _params.buttonBorderColor;
    _control.playButton.addEventListener(MouseEvent.CLICK, onPlayPauseClick);
    _control.volumeSlider.bgColor = _params.buttonBgColor;
    _control.volumeSlider.fgColor = _params.buttonFgColor;
    _control.volumeSlider.hiColor = _params.buttonHiColor;
    _control.volumeSlider.addEventListener(Slider.CLICK, onVolumeSliderClick);
    _control.volumeSlider.addEventListener(Slider.CHANGED, onVolumeSliderChanged);
    _control.seekBar.bgColor = _params.buttonBgColor;
    _control.seekBar.fgColor = _params.buttonFgColor;
    _control.seekBar.hiColor = _params.buttonHiColor;
    _control.seekBar.addEventListener(Slider.CHANGED, onSeekBarChanged);
    _control.seekBar.isStatic = !isRTMP;
    if (_control.fsButton != null) {
      _control.fsButton.bgColor = _params.buttonBgColor;
      _control.fsButton.fgColor = _params.buttonFgColor;
      _control.fsButton.hiColor = _params.buttonHiColor;
      _control.fsButton.borderColor = _params.buttonBorderColor;
      _control.fsButton.toFullscreen = (stage.displayState == StageDisplayState.NORMAL);
      _control.fsButton.addEventListener(MouseEvent.CLICK, onFullscreenClick);
    }
    addChild(_control);
    
    _debugdisp = new DebugDisplay();
    _debugdisp.visible = _params.debug;
    addChild(_debugdisp);

    if (false) {
      // menu testing.
      var menu:PopupMenuButtonOfDoom = new PopupMenuButtonOfDoom();
      menu.bgColor = _params.buttonBgColor;
      menu.fgColor = _params.buttonFgColor;
      menu.hiColor = _params.buttonHiColor;
      menu.borderColor = _params.buttonBorderColor;
      menu.x = menu.y = 100;
      menu.resize(100, 100);
      menu.addTextItem("Snarf.");
      menu.addTextItem("Goggy?");
      menu.addTextItem("IHKH!");
      addChild(menu);
      menu.addEventListener(Event.ENTER_FRAME, function (e:Event):void { menu.update(); });
      menu.addEventListener(MenuItemEvent.CHOOSE, function (e:MenuItemEvent):void { trace(e.item); });
    }

    stage.addEventListener(Event.RESIZE, onResize);
    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
    stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    resize();

    log("FlashVars:", expandAttrs(info.parameters));
    log("url:", _url);
    log("fullscreen:", _params.fullscreen);
    log("bufferTime:", _params.bufferTime);
    log("bufferTimeMax:", _params.bufferTimeMax);
    log("maxPauseBufferTime:", _params.maxPauseBufferTime);
    log("backBufferTime:", _params.backBufferTime);
    log("inBufferSeek:", _params.inBufferSeek);

    _connection = new NetConnection();
    _connection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
    _connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncErrorEvent);

    updateStatus(STOPPED);
    if (_params.autoplay) {
      connect();
    }
  }

  private function log(... args):void
  {
    var x:String = "";
    for each (var a:Object in args) {
      if (x.length != 0) x += " ";
      x += a;
    }
    _debugdisp.writeLine(x);
    trace(x);
  }

  private function expandAttrs(obj:Object):String
  {
    var x:String = null;
    for (var key:Object in obj) {
      var value:Object = obj[key];
      if (x == null) {
	x = key+"="+value;
      } else {
	x += ", "+key+"="+value;
      }
    }
    return x;
  }

  private function getBaseURL(url:String, proto:String="rtmp"):String
  {
    if (url != null && url.indexOf("://") < 0) {
      // Resolve a relative url.
      var info:LoaderInfo = LoaderInfo(this.root.loaderInfo);
      var basehref:String = info.loaderURL;
      var i:int;
      if (url.substr(0, 1) == "/") {
	i = basehref.indexOf("://");
	if (0 < i) {
	  basehref = basehref.substring(i+3);
	  i = basehref.indexOf("/");
	  if (i < 0) {
	    i = basehref.length;
	  }
	  url = proto+"://"+basehref.substr(0, i)+url;
	}
      } else {
	i = basehref.lastIndexOf("/");
	url = basehref.substr(0, i+1)+url;
      }
    }
    return url;
  }

  private function get isRTMP():Boolean
  {
    return (_url != null && _url.substr(0, 5) == "rtmp:");
  }

  private function onResize(e:Event):void
  {
    resize();
  }

  private function onFullScreen(e:FullScreenEvent):void
  {
    _control.fsButton.toFullscreen = !e.fullScreen;
  }

  private function onEnterFrame(e:Event):void
  {
    update();
  }

  private function onMouseDown(e:MouseEvent):void 
  {
    _control.show();
  }
  private function onMouseUp(e:MouseEvent):void 
  {
    _control.show();
  }
  private function onMouseMove(e:MouseEvent):void 
  {
    _control.show();
  }

  private function onKeyDown(e:KeyboardEvent):void 
  {
    _control.show();
    switch (e.keyCode) {
    case Keyboard.ESCAPE:	// Esc
    case 68:			// D
      // Toggle the debug window if debug = 1.
      if (_params.debug) {
	_debugdisp.visible = !_debugdisp.visible;
      }
      break;
    case Keyboard.SPACE:
      // Toggle play/stop.
      setPlayState(_control.playButton.toPlay);
      break;
    case Keyboard.LEFT:
      // Rewind for 10 sec.
      seekDelta(-10);
      break;
    case Keyboard.RIGHT:
      // Fast-forward for 10 sec.
      seekDelta(+10);
      break;
    case Keyboard.UP:
      // Rewind for 1 min.
      seekDelta(-60);
      break;
    case Keyboard.DOWN:
      // Fast-forward for 1 min.
      seekDelta(+60);
      break;
    case Keyboard.PAGE_UP:
      // Rewind for 10 min.
      seekDelta(-600);
      break;
    case Keyboard.PAGE_DOWN:
      // Fast-forward for 10 min.
      seekDelta(+600);
      break;
    case Keyboard.HOME:
      // Rewind to the beginning.
      seek(0);
      break;
    }
  }

  private function onNetStatusEvent(ev:NetStatusEvent):void
  {
    log("onNetStatusEvent:", expandAttrs(ev.info));
    switch (ev.info.code) {
    case "NetConnection.Connect.Failed":
    case "NetConnection.Connect.Rejected":
    case "NetConnection.Connect.InvalidApp":
      updateStatus(STOPPED, "Failed");
      break;
      
    case "NetConnection.Connect.Success":
      var nc:Netconnection = ev.target;
      _stream = new NetStream(nc);
      _stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
      _stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncErrorEvent);
      _stream.client = new Object();
      _stream.client.onMetaData = onMetaData;
      _stream.client.onCuePoint = onCuePoint;
      _stream.client.onPlayStatus = onPlayStatus;
      _stream.inBufferSeek = _params.inBufferSeek;
      _stream.bufferTime = _params.bufferTime;
      _stream.bufferTimeMax = _params.bufferTimeMax;
      _stream.maxPauseBufferTime = _params.maxPauseBufferTime;
      _stream.backBufferTime = _params.backBufferTime;
      _video.attachNetStream(_stream);
      updateVolume(_control.volumeSlider);
      startPlaying(_params.start);
      break;

    case "NetConnection.Connect.Closed":
      stopPlaying();
      _video.attachNetStream(null);
      _stream.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
      _stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncErrorEvent);
      _stream.client = null;
      _stream = null;
      updateStatus(STOPPED, "Disconnected");
      break;

    case "NetStream.Play.Start":
      updateStatus(STARTING);
      break;

    case "NetStream.Play.Stop":
    case "NetStream.Play.Complete":
    case "NetStream.Buffer.Flush":
      updateStatus(STOPPED);
      break;

    case "NetStream.Buffer.Empty":
      updateStatus(STARTING);
      break;

    case "NetStream.Buffer.Full":
      if (_state == STOPPING) {
	stopPlaying();
      } else {
	updateStatus(STARTED);
      }
      break;
    }
  }

  private function onImageLoaded(event:Event):void
  {
    resize();
  }

  private function onMetaData(info:Object):void
  {
    log("onMetaData:", expandAttrs(info));
    _videoMetaData = info;
    if (0 < _videoMetaData.duration) {
      // Show the seek bar when the video duration is defined.
      _control.statusDisplay.visible = false;
      _control.seekBar.duration = _videoMetaData.duration;
      _control.seekBar.bytesTotal = _videoMetaData.filesize;
      _control.seekBar.visible = true;
    }
    updateStatus(_state);
    resize();
  }

  private function onCuePoint(info:Object):void
  {
    log("onCuePoint:", expandAttrs(info));
  }

  private function onPlayStatus(info:Object):void
  {
    log("onPlayStatus:", expandAttrs(info));
  }

  private function onAsyncErrorEvent(ev:AsyncErrorEvent):void
  {
    log("onAsyncErrorEvent:", ev.error);
  }

  private function onOverlayClick(e:MouseEvent):void 
  {  
    var overlay:OverlayButton = OverlayButton(e.target);
    overlay.show();
    setPlayState(overlay.toPlay);
  }

  private function onPlayPauseClick(e:Event):void
  {
    var button:PlayPauseButton = PlayPauseButton(e.target);
    setPlayState(button.toPlay);
  }

  private function onVolumeSliderClick(e:Event):void
  {
    var slider:VolumeSlider = VolumeSlider(e.target);
    slider.muted = !slider.muted;
    updateVolume(slider);
  }
  
  private function onVolumeSliderChanged(e:Event):void
  {
    var slider:VolumeSlider = VolumeSlider(e.target);
    updateVolume(slider);
  }

  private function onSeekBarChanged(e:Event):void
  {
    var seekbar:SeekBar = SeekBar(e.target);
    seek(seekbar.time);
  }

  private function onFullscreenClick(e:Event):void
  {
    var button:FullscreenButton = FullscreenButton(e.target);
    stage.displayState = ((button.toFullscreen)? 
			  StageDisplayState.FULL_SCREEN : 
			  StageDisplayState.NORMAL);
  }

  private function proportionalScaleToStage(obj:DisplayObject, w:int, h:int):void
  {
    var r:Number = Math.min((stage.stageWidth / w),
			    (stage.stageHeight / h));
    obj.width = w*r;
    obj.height = h*r;
    obj.x = (stage.stageWidth - obj.width)/2;
    obj.y = (stage.stageHeight - obj.height)/2;
  }

  private function updateVolume(slider:VolumeSlider):void
  {
    if (_stream != null) {
      var transform:SoundTransform = 
	new SoundTransform((slider.muted)? 0 : slider.value);
      _stream.soundTransform = transform;
    }
  }

  private function updateStatus(state:String, text:String=null):void
  {
    _state = state;
    switch (_state) {
    case STARTING:
      _overlay.toPlay = true;
      _overlay.autohide = true;
      _control.playButton.toPlay = false;
      if (text == null) {
	text = "Starting...";
      }
      break;

    case STARTED:
      _control.seekBar.unlock();
      _overlay.toPlay = false;
      _overlay.autohide = true;
      _control.playButton.toPlay = false;
      _control.autohide = true;
      if (text == null) {
	text = "Playing";
      }
      break;

    case STOPPING:
      _overlay.toPlay = false;
      _overlay.autohide = true;
      _control.playButton.toPlay = false;
      if (text == null) {
	text = "Stopping...";
      }
      break;

    case STOPPED:
      _overlay.toPlay = true;
      _overlay.autohide = false;
      _control.playButton.toPlay = true;
      _control.autohide = false;
      if (text == null) {
	text = "Stopped";
      }
      break;
    }

    _control.statusDisplay.text = text;
  }

  private function startPlaying(start:Number):void
  {
    if (_url != null && _stream != null) {
      var streamPath:String = _url;
      if (isRTMP) {
	streamPath = _url.substr(_url.lastIndexOf("/")+1);
      }
      updateStatus(STARTING);
      log("Starting:", streamPath, start);
      _stream.play(streamPath, start);
    }
  }

  private function stopPlaying():void
  {
    if (_stream != null) {
      log("Stopping");
      updateStatus(STOPPING);
      _stream.close();
    }
  }

  private function resize():void
  {
    log("resize:", stage.stageWidth+","+stage.stageHeight);

    if (_videoMetaData != null) {
      proportionalScaleToStage(_video, _videoMetaData.width, _videoMetaData.height);
    }
    if (_imageLoader != null) {
      proportionalScaleToStage(_imageLoader, _imageLoader.width, _imageLoader.height);
    }

    _overlay.resize(stage.stageWidth, stage.stageHeight);
    _overlay.x = 0;
    _overlay.y = 0;

    _control.resize(stage.stageWidth, 28);
    _control.x = 0;
    _control.y = stage.stageHeight-_control.height;

    _debugdisp.resize(stage.stageWidth, stage.stageHeight-_control.height);
    _debugdisp.x = 0;
    _debugdisp.y = 0;
  }

  private function update():void
  {
    _overlay.update();
    _control.update();
    if (_stream != null) {
      if (_state == STARTED) {
	_control.seekBar.time = _stream.time;
      }
      if (0 < _stream.bytesTotal) {
	_control.seekBar.bytesLoaded = _stream.bytesLoaded;
      }
      if (_debugdisp.visible) {
	_debugdisp.update(_stream);
      }
    }
  }

  public function connect():void
  {
    if (_url != null && !_connection.connected) {
      var url:String = null;
      if (isRTMP) {
	var i:int = _url.lastIndexOf("/");
	url = _url.substr(0, i);
      }
      log("Connecting:", url);
      _control.statusDisplay.text = "Connecting...";
      _connection.connect(url);
    }
  }

  public function setPlayState(playing:Boolean):void
  {
    log("setPlayState:", playing);
    switch (_state) {
    case STARTING:
      if (!playing) {
	updateStatus(STOPPING);
      }
      break;
    case STARTED:
      if (!playing) {
	stopPlaying();
      }
      break;
    case STOPPED:
      if (playing) {
	if (_connection.connected) {
	  startPlaying(_control.seekBar.time);
	} else {
	  connect();
	}
      }
      break;
    }
  }

  public function seek(t:Number):void
  {
    log("seek:", t);
    if (_stream != null) {
      _stream.seek(t);
    }
  }

  public function seekDelta(dt:Number):void
  {
    log("seekDelta:", dt);
    if (_stream != null) {
      _stream.seek(_stream.time + dt);
    }
  }

}

} // package

/// Private classed below.

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.net.NetStream;
import flash.net.NetStreamInfo;
import flash.ui.Keyboard;
import flash.utils.getTimer;
import flash.geom.Point;

//  Params
//  Object to hold the parameters given by FlashVars.
//
class Params extends Object
{
  public var debug:Boolean = false;
  public var url:String = null;
  public var bufferTime:Number = 1.0;
  public var bufferTimeMax:Number = 0.0;
  public var maxPauseBufferTime:Number = 30.0;
  public var backBufferTime:Number = 30.0;
  public var inBufferSeek:Boolean = false;
  public var fullscreen:Boolean = false;
  public var smoothing:Boolean = false;
  public var start:Number = 0.0;
  public var autoplay:Boolean = true;

  public var bgColor:uint = 0x000000;
  public var buttonBgColor:uint = 0x448888ff;
  public var buttonFgColor:uint = 0xcc888888;
  public var buttonHiColor:uint = 0xffeeeeee;
  public var buttonBorderColor:uint = 0x88ffffff;
  public var volumeMutedColor:uint = 0xffff0000;
  public var imageUrl:String = null;

  public function Params(obj:Object)
  {
    super();
    if (obj != null) {
      // debug
      if (obj.debug) {
	debug = parseBoolean(obj.debug);
      }
      // url
      if (obj.url) {
	url = obj.url;
      }
      // bufferTime
      if (obj.bufferTime) {
	bufferTime = parseFloat(obj.bufferTime);
	bufferTimeMax = bufferTime;
	maxPauseBufferTime = bufferTime;
      }
      // bufferTimeMax
      if (obj.bufferTimeMax) {
	bufferTimeMax = parseFloat(obj.bufferTimeMax);
      }
      // maxPauseBufferTime
      if (obj.maxPauseBufferTime) {
	maxPauseBufferTime = parseFloat(obj.maxPauseBufferTime);
      }
      // backBufferTime
      if (obj.backBufferTime) {
	backBufferTime = parseFloat(obj.backBufferTime);
      }
      // inBufferSeek
      if (obj.inBufferSeek) {
	inBufferSeek = parseBoolean(obj.inBufferSeek);
      }
      // fullscreen
      if (obj.fullscreen) {
	fullscreen = parseBoolean(obj.fullscreen);
      }
      // smoothing
      if (obj.smoothing) {
	smoothing = parseBoolean(obj.smoothing);
      }
      // start
      if (obj.start) {
	start = parseFloat(obj.start);
      }
      // autoplay
      if (obj.autoplay) {
	autoplay = parseBoolean(obj.autoplay);
      }

      // bgColor
      if (obj.bgColor) {
	bgColor = parseColor(obj.bgColor);
      }
      // buttonBgColor
      if (obj.buttonBgColor) {
	buttonBgColor = parseColor(obj.buttonBgColor);
      }
      // buttonFgColor
      if (obj.buttonFgColor) {
	buttonFgColor = parseColor(obj.buttonFgColor);
      }
      // buttonHiColor
      if (obj.buttonHiColor) {
	buttonHiColor = parseColor(obj.buttonHiColor);
      }
      // buttonBorderColor
      if (obj.buttonBorderColor) {
	buttonBorderColor = parseColor(obj.buttonBorderColor);
      }
      // volumeMutedColor
      if (obj.volumeMutedColor) {
	volumeMutedColor = parseColor(obj.volumeMutedColor);
      }
      // imageUrl
      if (obj.imageUrl) {
	imageUrl = obj.imageUrl;
      }
    }
  }

  private function parseBoolean(v:String):Boolean
  {
    return (parseInt(v) != 0);
  }

  private function parseColor(v:String):uint
  {
    if (v.substr(0, 1) == "#") {
      v = v.substr(1);
    }
    return parseInt(v, 16);
  }
}


//  Control
//  Base class for buttons/sliders.
//
class Control extends Sprite
{
  public var bgColor:uint = 0x448888ff;
  public var fgColor:uint = 0xcc888888;
  public var hiColor:uint = 0xffeeeeee;
  public var borderColor:uint = 0x88ffffff;

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
    graphics.beginFill(bgColor, (bgColor>>>24)/255);
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


//  Button
//  Generic button class.
//  
class Button extends Control
{
  public function get buttonSize():int
  {
    return Math.min(width, height);
  }

  public override function repaint():void
  {
    super.repaint();

    if (highlit) {
      graphics.lineStyle(0, borderColor, (borderColor>>>24)/255);
      graphics.drawRect(0, 0, width, height);
    }
  }
}


//  Slider
//  Generic slider class.
// 
class Slider extends Button
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


//  MenuItemEvent
//
class MenuItemEvent extends Event
{
  public static const CHOOSE:String = "MenuItemEvent.CHOOSE";

  public var item:MenuItem;

  public function MenuItemEvent(item:MenuItem=null)
  {
    super(CHOOSE);
    this.item = item;
  }
}


//  MenuItem
// 
class MenuItem extends Control
{
  public var value:Object;

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


//  TextMenuItem
// 
class TextMenuItem extends MenuItem
{
  private var _text:TextField;

  public function TextMenuItem()
  {
    super();
    _text = new TextField();
    _text.selectable = false;
    _text.autoSize = TextFieldAutoSize.LEFT;
    addChild(_text);
  }

  public function get label():String
  {
    return _text.text;
  }

  public function set label(v:String):void
  {
    _text.text = v;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();

    if (highlit) {
      _text.textColor = hiColor;
    } else {
      _text.textColor = fgColor;
    }
  }
}


//  MenuPopup
//
class MenuPopup extends Button
{
  private var _items:Array;
  private var _chosen:MenuItem;

  public function MenuPopup()
  {
    super();
    _items = new Array();
  }

  public function get chosen():MenuItem
  {
    return _chosen;
  }

  public function addTextItem(label:String, value:Object=null):void
  {
    var item:TextMenuItem = new TextMenuItem();
    item.label = label;
    item.value = (value != null)? value : label;
    addItem(item);
  }

  public function addItem(item:MenuItem):void
  {
    _items.push(item);
    item.x = 0;
    item.y = height;
    item.addEventListener(MenuItemEvent.CHOOSE, onItemChosen);
    addChild(item);
    resize(width, height);
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


//  PopupMenuButtonOfDoom
//
class PopupMenuButtonOfDoom extends Button
{
  public var minDuration:int = 100;

  private var _popup:MenuPopup;

  public function PopupMenuButtonOfDoom()
  {
    super();
    _popup = new MenuPopup();
    _popup.bgColor = bgColor;
    _popup.fgColor = fgColor;
    _popup.hiColor = hiColor;
    _popup.borderColor = borderColor;
    _popup.addEventListener(MenuItemEvent.CHOOSE, onItemChosen);
  }

  public function addTextItem(label:String, value:Object=null):void
  {
    _popup.addTextItem(label, value);
  }

  public function addItem(item:MenuItem):void
  {
    _popup.addItem(item);
  }
  
  protected virtual function onItemChosen(e:MenuItemEvent):void 
  {
    dispatchEvent(new MenuItemEvent(e.item));
    parent.removeChild(_popup);
  }

  protected override function onMouseDownLocal(e:MouseEvent):void 
  {
    super.onMouseDownLocal(e);
    if (_popup.parent != null) {
      parent.removeChild(_popup);
    } else {
      var p:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));
      _popup.x = p.x;
      _popup.y = p.y;
      parent.addChild(_popup);
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


//  ControlBar
//  Bar shown at the bottom of screen containing buttons, etc.
//
class ControlBar extends Sprite
{
  public var margin:int = 4;
  public var fadeDuration:int = 1000;

  public var statusDisplay:StatusDisplay;
  public var playButton:PlayPauseButton;
  public var volumeSlider:VolumeSlider;
  public var seekBar:SeekBar;
  public var fsButton:FullscreenButton;

  private var _autohide:Boolean;
  private var _timeout:int;

  public function ControlBar(fullscreen:Boolean=false)
  {
    super();
    _timeout = -fadeDuration;

    playButton = new PlayPauseButton();
    playButton.toPlay = true;
    addChild(playButton);

    volumeSlider = new VolumeSlider();
    volumeSlider.value = 1.0;
    addChild(volumeSlider);

    seekBar = new SeekBar();
    seekBar.visible = false;
    addChild(seekBar);
    
    if (fullscreen) {
      fsButton = new FullscreenButton();
      addChild(fsButton);
    }

    statusDisplay = new StatusDisplay();
    addChild(statusDisplay);
  }
  
  public function get autohide():Boolean
  {
    return _autohide;
  }

  public function set autohide(value:Boolean):void
  {
    _autohide = value;
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
    if (fsButton != null) {
      fsButton.update();
    }
  }
}


//  VolumeSlider
//  A volume slider.  (part of ControlBar)
//
class VolumeSlider extends Slider
{
  public var muteColor:uint = 0xffff0000;

  private var _value:Number = 0;
  private var _muted:Boolean = false;
  
  protected override function onMouseDrag(e:MouseEvent):void 
  {
    super.onMouseDrag(e);
    var size:int = buttonSize/8;
    var w:int = (width-size*2);
    value = (e.localX-size)/w;
    dispatchEvent(new Event(CHANGED));
  }

  public function get value():Number
  {
    return _value;
  }

  public function set value(v:Number):void
  {
    v = Math.max(0, Math.min(1, v));
    if (_value != v) {
      _value = v;
      invalidate();
    }
  }

  public function get muted():Boolean
  {
    return _muted;
  }

  public function set muted(value:Boolean):void
  {
    _muted = value;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = buttonSize/4;
    var color:uint = (highlit)? hiColor : fgColor;
    var cx:int = width/2;
    var cy:int = height/2;

    graphics.lineStyle(0, color, (color>>>24)/255);
    graphics.moveTo(size, height-size);
    graphics.lineTo(width-size, size);
    graphics.lineTo(width-size, height-size);
    graphics.lineTo(size, height-size);

    var w:int = (width-size*2);
    var h:int = (height-size*2);
    graphics.beginFill(color, (color>>>24)/255);
    graphics.moveTo(size, height-size);
    graphics.lineTo(size+_value*w, height-size-_value*h);
    graphics.lineTo(size+_value*w, height-size);
    graphics.endFill();

    if (_muted) {
      graphics.lineStyle(2, muteColor, (muteColor>>>24)/255);
      graphics.moveTo(cx-size, cy-size);
      graphics.lineTo(cx+size, cy+size);
    }
  }
}


//  SeekBar
//  A horizontal seek bar.  (part of ControlBar)
//
class SeekBar extends Slider
{
  public var margin:int = 4;
  public var barSize:int = 2;

  private var _text:TextField;
  private var _duration:Number = 0;
  private var _bytesTotal:uint = 0;
  private var _bytesLoaded:uint = 0;
  private var _static:Boolean = false;
  private var _locked:Boolean = false;
  private var _time:Number = 0;
  private var _goal:Number = 0;

  public function SeekBar()
  {
    super();
    _text = new TextField();
    _text.x = margin;
    _text.selectable = false;
    _text.autoSize = TextFieldAutoSize.LEFT;
    addChild(_text);
  }

  public function setTextFormat(textFormat:TextFormat, embedFonts:Boolean=false):void
  {
    _text.defaultTextFormat = textFormat;
    _text.embedFonts = embedFonts;
    invalidate();
  }
  
  protected override function onMouseDownLocal(e:MouseEvent):void 
  {
    super.onMouseDownLocal(e);
    updateGoal(e.localX);
  }

  protected override function onMouseDrag(e:MouseEvent):void 
  {
    super.onMouseDrag(e);
    updateGoal(e.localX);
  }

  protected override function onMouseUpLocal(e:MouseEvent):void 
  {
    super.onMouseUpLocal(e);
    dispatchEvent(new Event(CHANGED));
  }

  private function updateGoal(x:int):void
  {
    var w:int = (width-margin-leftMargin);
    var v:Number = (x-leftMargin)/w;
    v = Math.min(v, availableRatio);
    _locked = true;
    _goal = Math.max(0, Math.min(1, v)) * _duration;
    invalidate();
  }

  public function get leftMargin():int
  {
    return (margin+_text.width);
  }

  public function get duration():Number
  {
    return _duration;
  }

  public function set duration(v:Number):void
  {
    _duration = v;
    invalidate();
  }

  public function set isStatic(v:Boolean):void
  {
    _static = v;
    invalidate();
  }

  public function set bytesTotal(v:uint):void
  {
    _bytesTotal = v;
    invalidate();
  }

  public function set bytesLoaded(v:uint):void
  {
    _bytesLoaded = v;
    invalidate();
  }

  public function get availableRatio():Number
  {
    if (_static && 0 < _bytesTotal) {
      return _bytesLoaded / Number(_bytesTotal);
    } else {
      return 1.0;
    }
  }

  public function set time(v:Number):void
  {
    _time = v;
    invalidate();
  }

  public function get time():Number
  {
    return (_locked)? _goal : _time;
  }

  public function unlock():void
  {
    _locked = false;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = barSize;
    var color:uint = (highlit)? hiColor : fgColor;
    var t:Number = (_locked)? _goal : _time;

    _text.text = (Math.floor(t/3600)+":"+
		  format2(Math.floor(t/60)%60, "0")+":"+
		  format2(t%60, "0")+" ");
    _text.textColor = color;

    var w:int = (width-margin-leftMargin);
    var h:int = (height-margin*2);
    graphics.beginFill(color, (color>>>24)/255);
    graphics.drawRect(leftMargin, (height-size)/2, w*availableRatio, size);
    if (0 < _duration) {
      graphics.drawRect(leftMargin+w*t/_duration-size, margin, size*2, h);
    }
    graphics.endFill();
  }

  private function format2(v:int, c:String=" "):String
  {
    return ((v < 10)? c+v : String(v));
  }
}


//  FullscreenButton
//  Fullscreen/Windowed toggle button. (part of ControlBar)
//
class FullscreenButton extends Button
{
  private var _toFullscreen:Boolean = false;

  public function get toFullscreen():Boolean
  {
    return _toFullscreen;
  }

  public function set toFullscreen(value:Boolean):void
  {
    _toFullscreen = value;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = buttonSize/16;
    var color:uint = (highlit)? hiColor : fgColor;
    var cx:int = width/2 + ((pressed)? 1 : 0);
    var cy:int = height/2 + ((pressed)? 1 : 0);

    if (_toFullscreen) {
      graphics.beginFill(color, (color>>>24)/255);
      graphics.drawRect(cx-size*7, cy-size*4, size*14, size*8);
      graphics.endFill();
    } else {
      graphics.lineStyle(0, color, (color>>>24)/255);
      graphics.drawRect(cx-size*7, cy-size*5, size*10, size*6);
      graphics.drawRect(cx-size*2, cy-size*1, size*9, size*7);
    }
  }
}


//  PlayPauseButton
//  Play/pause toggle button. (part of ControlBar)
//
class PlayPauseButton extends Button
{
  private var _toPlay:Boolean = false;

  public function get toPlay():Boolean
  {
    return _toPlay;
  }

  public function set toPlay(value:Boolean):void
  {
    _toPlay = value;
    invalidate();
  }

  public override function repaint():void
  {
    super.repaint();
    var size:int = buttonSize/16;
    var color:uint = (highlit)? hiColor : fgColor;
    var cx:int = width/2 + ((pressed)? 1 : 0);
    var cy:int = height/2 + ((pressed)? 1 : 0);

    if (_toPlay) {
      graphics.beginFill(color, (color>>>24)/255);
      graphics.moveTo(cx-size*4, cy-size*4);
      graphics.lineTo(cx-size*4, cy+size*4);
      graphics.lineTo(cx+size*4, cy);
      graphics.endFill();
    } else {
      graphics.beginFill(color, (color>>>24)/255);
      graphics.drawRect(cx-size*3, cy-size*4, size*2, size*8);
      graphics.drawRect(cx+size*1, cy-size*4, size*2, size*8);
      graphics.endFill();
    }
  }
}


//  StatusDisplay
//  Shows a text status. (part of ControlBar)
//
class StatusDisplay extends Control
{
  private var _text:TextField;

  public function StatusDisplay()
  {
    super();
    _text = new TextField();
    _text.selectable = false;
    addChild(_text);
  }

  public function setTextFormat(textFormat:TextFormat, embedFonts:Boolean=false):void
  {
    _text.defaultTextFormat = textFormat;
    _text.embedFonts = embedFonts;
    invalidate();
  }
  
  public function get text():String
  {
    return _text.text;
  }
  public function set text(value:String):void
  {
    _text.text = value;
  }

  public override function resize(w:int, h:int):void
  {
    super.resize(w, h);
    _text.width = w;
    _text.height = h;
  }

  public override function repaint():void
  {
    super.repaint();
    var color:uint = (highlit)? hiColor : fgColor;
    _text.textColor = color;
  }
}


//  OverlayButton
//  A transparent button shown over the video.
//
class OverlayButton extends Sprite
{
  public var buttonSize:int = 100;
  public var fadeDuration:int = 2000;
  public var buttonBgColor:uint = 0x448888ff;
  public var buttonFgColor:uint = 0xcc888888;

  private var _size:int;
  private var _width:int;
  private var _height:int;
  private var _invalidated:Boolean;
  private var _toPlay:Boolean;
  private var _autohide:Boolean;
  private var _timeout:int;

  public function OverlayButton()
  {
    super();
    _timeout = -fadeDuration;
    alpha = 0;
  }

  public function get toPlay():Boolean
  {
    return _toPlay;
  }

  public function set toPlay(value:Boolean):void
  {
    _toPlay = value;
    _invalidated = true;
  }

  public function get autohide():Boolean
  {
    return _autohide;
  }

  public function set autohide(value:Boolean):void
  {
    _autohide = value;
  }

  public function resize(w:int, h:int):void
  {
    _width = w;
    _height = h;
    _invalidated = true;
  }
  
  public function show():void
  {
    _timeout = getTimer();
    _invalidated = true;
  }

  public function repaint():void
  {
    graphics.clear();
    graphics.beginFill(0, 0);
    graphics.drawRect(0, 0, _width, _height);
    graphics.endFill();

    var size:int = buttonSize/16;
    var cx:int = width/2;
    var cy:int = height/2;

    graphics.beginFill(buttonBgColor, (buttonBgColor>>>24)/255);
    graphics.drawRect(cx-buttonSize/2, cy-buttonSize/2, buttonSize, buttonSize);
    graphics.endFill();
    if (_toPlay) {
      graphics.beginFill(buttonFgColor, (buttonFgColor>>>24)/255);
      graphics.moveTo(cx-size*4, cy-size*4);
      graphics.lineTo(cx-size*4, cy+size*4);
      graphics.lineTo(cx+size*4, cy);
      graphics.endFill();
    } else {
      graphics.beginFill(buttonFgColor, (buttonFgColor>>>24)/255);
      graphics.drawRect(cx-size*3, cy-size*4, size*2, size*8);
      graphics.drawRect(cx+size*1, cy-size*4, size*2, size*8);
      graphics.endFill();
    }
  }
  
  public function update():void
  {
    if (_invalidated) {
      _invalidated = false;
      repaint();
    }

    if (_autohide) {
      var a:Number = (_timeout - getTimer())/fadeDuration + 1.0;
      alpha = Math.min(Math.max(a, 0.0), 1.0);
    } else {
      alpha = 1.0;
    }
  }
}


//  DebugDisplay
//  Text areas showing the debug info.
//
class DebugDisplay extends Sprite
{
  private var _logger:TextField;
  private var _playstat:TextField;
  private var _streaminfo:TextField;

  public function DebugDisplay()
  {
    super();
    _logger = new TextField();
    _logger.multiline = true;
    _logger.wordWrap = true;
    _logger.border = true;
    _logger.background = true;
    _logger.type = TextFieldType.DYNAMIC;
    _logger.width = 400;
    _logger.height = 100;
    addChild(_logger);

    _playstat = new TextField();
    _playstat.multiline = true;
    _playstat.textColor = 0xffffff;
    _playstat.type = TextFieldType.DYNAMIC;
    _playstat.text = "\n\n\n\n\n\n\n\n";
    _playstat.width = 200;
    _playstat.height = _playstat.textHeight+1;
    addChild(_playstat);

    _streaminfo = new TextField();
    _streaminfo.multiline = true;
    _streaminfo.textColor = 0xffff00;
    _streaminfo.type = TextFieldType.DYNAMIC;
    _streaminfo.text = "\n\n\n\n\n\n\n\n\n\n\n";
    _streaminfo.width = 200;
    _streaminfo.height = _streaminfo.textHeight+1;
    addChild(_streaminfo);
  }

  public function writeLine(x:String):void
  {
    _logger.appendText(x+"\n");
    _logger.scrollV = _logger.maxScrollV;
  }

  public function resize(w:int, h:int):void
  {
    _playstat.x = w - _playstat.width;
    _playstat.y = h - _playstat.height;
    _streaminfo.x = 0;
    _streaminfo.y = h - _streaminfo.height;
  }
  
  public function update(stream:NetStream):void
  {
    if (!visible) return;

    var text:String;
    text = ("time: "+stream.time+"\n"+
	    "bufferLength: "+stream.bufferLength+"\n"+
	    "backBufferLength: "+stream.backBufferLength+"\n"+
	    "bytesLoaded: "+stream.bytesLoaded+"\n"+
	    "bytesTotal: "+stream.bytesTotal+"\n"+
	    "currentFPS: "+Math.floor(stream.currentFPS)+"\n"+
	    "liveDelay: "+stream.liveDelay+"\n");
    _playstat.text = text;

    var info:NetStreamInfo = stream.info;
    text = ("isLive: "+info.isLive+"\n"+
	    "byteCount: "+info.byteCount+"\n"+
	    "audioBufferLength: "+info.audioBufferLength+"\n"+
	    "videoBufferLength: "+info.videoBufferLength+"\n"+
	    "currentBytesPerSecond: "+Math.floor(info.currentBytesPerSecond)+"\n"+
	    "maxBytesPerSecond: "+Math.floor(info.maxBytesPerSecond)+"\n"+
	    "audioBytesPerSecond: "+Math.floor(info.audioBytesPerSecond)+"\n"+
	    "videoBytesPerSecond: "+Math.floor(info.videoBytesPerSecond)+"\n"+
	    "playbackBytesPerSecond: "+Math.floor(info.playbackBytesPerSecond)+"\n"+
	    "droppedFrames: "+info.droppedFrames+"\n");
    _streaminfo.text = text;
  }
}
