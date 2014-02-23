// VGAPlayer
//

package {

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.LoaderInfo;
import flash.display.StageDisplayState;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.NetStatusEvent;
import flash.events.AsyncErrorEvent;
import flash.media.Video;
import flash.media.SoundTransform;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.ui.Keyboard;

//  Main 
//
[SWF(backgroundColor="#000000")]
public class Main extends Sprite
{
  private var _params:Params;
  private var _control:ControlBar;
  private var _debug:DebugDisplay;

  private var _connection:NetConnection;
  private var _stream:NetStream;
  private var _video:Video;
  private var _overlay:VideoOverlay;
  private var _playing:Boolean;
  private var _buffull:Boolean;

  // Main()
  public function Main()
  {
    var info:LoaderInfo = LoaderInfo(this.root.loaderInfo);
    _params = new Params(info.loaderURL, info.parameters);

    _connection = new NetConnection();
    _connection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
    _connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncErrorEvent);

    _video = new Video();
    addChild(_video);

    _control = new ControlBar(stage.stageWidth, 20, 4, _params.fullscreen);
    _control.y = stage.stageHeight-_control.height;
    _control.playButton.addEventListener(MouseEvent.CLICK, onPlayPauseClick);
    _control.volumeSlider.addEventListener(Slider.CLICK, onVolumeSliderClick);
    _control.volumeSlider.addEventListener(Slider.CHANGED, onVolumeSliderChanged);
    if (_control.fsButton != null) {
      _control.fsButton.toFullscreen = (stage.displayState == StageDisplayState.NORMAL);
      _control.fsButton.addEventListener(MouseEvent.CLICK, onFullscreenClick);
    }
    addChild(_control);

    _overlay = new VideoOverlay(stage.stageWidth, stage.stageHeight-_control.height);
    _overlay.addEventListener(MouseEvent.CLICK, onOverlayClick);
    addChild(_overlay);

    _debug = new DebugDisplay(_overlay.width, _overlay.height);
    debugMode = _params.debug;

    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
    stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);

    log("FlashVars: "+expandAttrs(info.parameters));
    log("debug: "+_params.debug);
    log("url: "+_params.url);
    log("fullscreen: "+_params.fullscreen);
    log("bufferTime: "+_params.bufferTime);
    log("bufferTimeMax: "+_params.bufferTimeMax);
    log("maxPauseBufferTime: "+_params.maxPauseBufferTime);

    connect();
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

  private function log(... args):void
  {
    var x:String = "";
    for each (var a:Object in args) {
      if (x.length != 0) x += " ";
      x += a;
    }
    _debug.log(x);
    trace(x);
  }

  private function setCenter(obj:DisplayObject):void
  {
    obj.x = (stage.stageWidth - obj.width)/2;
    obj.y = (stage.stageHeight - obj.height)/2;
  }
  
  public function get debugMode():Boolean
  {
    return _overlay.contains(_debug);
  }
  public function set debugMode(value:Boolean):void
  {
    if (value && !_overlay.contains(_debug)) {
      _overlay.addChild(_debug);
    } else if (!value && _overlay.contains(_debug)) {
      _overlay.removeChild(_debug);
    }
    log("debugMode: "+value);
  }

  protected function onEnterFrame(e:Event):void
  {
    _overlay.update();
    _control.update();
    if (debugMode && _stream != null) {
      _debug.update(_stream);
    }
  }

  protected function onKeyDown(e:KeyboardEvent):void 
  {
    switch (e.keyCode) {
    case Keyboard.ESCAPE:	// Esc
    case 68:			// D
      debugMode = !debugMode;
      break;
    case Keyboard.SPACE:
      setPlayState(!_playing);
      break;
    }
  }

  protected function onKeyUp(e:KeyboardEvent):void 
  {
  }

  protected function onMouseMove(e:MouseEvent):void 
  {
    _control.show();
  }

  private function onOverlayClick(e:MouseEvent):void 
  {  
    var overlay:VideoOverlay = VideoOverlay(e.target);
    var playing:Boolean = !_playing;
    overlay.show(playing);
    setPlayState(playing);
  }

  private function onPlayPauseClick(e:Event):void
  {
    var button:PlayPauseButton = PlayPauseButton(e.target);
    if (!button.busy) {
      setPlayState(button.toPlay);
    }
  }

  private function _updateVolume(slider:VolumeSlider):void
  {
    if (_stream != null) {
      var transform:SoundTransform = 
	new SoundTransform((slider.muted)? 0 : slider.value);
      _stream.soundTransform = transform;
    }
  }

  private function onVolumeSliderClick(e:Event):void
  {
    var slider:VolumeSlider = VolumeSlider(e.target);
    slider.muted = !slider.muted;
    _updateVolume(slider);
  }
  
  private function onVolumeSliderChanged(e:Event):void
  {
    var slider:VolumeSlider = VolumeSlider(e.target);
    _updateVolume(slider);
  }

  private function onFullscreenClick(e:Event):void
  {
    var button:FullscreenButton = FullscreenButton(e.target);
    stage.displayState = ((button.toFullscreen)? 
			  StageDisplayState.FULL_SCREEN : 
			  StageDisplayState.NORMAL);
    button.toFullscreen = !button.toFullscreen;
  }

  private function onNetStatusEvent(ev:NetStatusEvent):void
  {
    log("onNetStatusEvent: "+expandAttrs(ev.info));
    switch (ev.info.code) {
    case "NetConnection.Connect.Success":
      var nc:Netconnection = ev.target;
      _stream = new NetStream(nc);
      _stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
      _stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncErrorEvent);
      _stream.client = new Object();
      _stream.client.onMetaData = onMetaData;
      _stream.client.onCuePoint = onCuePoint;
      _stream.client.onPlayStatus = onPlayStatus;
      _stream.bufferTime = _params.bufferTime;
      _stream.bufferTimeMax = _params.bufferTimeMax;
      _stream.maxPauseBufferTime = _params.maxPauseBufferTime;
      _updateVolume(_control.volumeSlider);
      _control.autohide = false;
      _control.status.text = "Connected";
      play();
      break;

    case "NetConnection.Connect.Failed":
    case "NetConnection.Connect.Rejected":
    case "NetConnection.Connect.InvalidApp":
      _control.autohide = false;
      _control.status.text = "Failed";
      break;

    case "NetConnection.Connect.Closed":
      stop();
      _stream = null;
      _control.autohide = false;
      _control.status.text = "Disconnected";
      break;
      
    case "NetStream.Play.Start":
      _playing = true;
      _buffull = false;
      _control.autohide = false;
      _control.playButton.busy = false;
      _control.playButton.toPlay = false;
      _control.status.text = "Buffering...";
      break;

    case "NetStream.Play.Stop":
    case "NetStream.Play.Complete":
      _playing = false;
      _buffull = false;
      _control.autohide = false;
      _control.playButton.busy = false;
      _control.playButton.toPlay = true;
      _control.status.text = "Stopped";
      break;

    case "NetStream.Buffer.Empty":
      if (_playing) {
	_buffull = false;
	_control.autohide = false;
	_control.status.text = "Buffering...";
      }
      break;
    case "NetStream.Buffer.Full":
      if (_playing) {
	_buffull = true;
	_control.autohide = true;
	_control.status.text = "Playing";
      }
      break;
    }
  }

  private function onMetaData(info:Object):void
  {
    log("onMetaData: "+expandAttrs(info));
    var r:Number = Math.min((stage.stageWidth / info.width),
			    (stage.stageHeight / info.height));
    _video.width = info.width*r;
    _video.height = info.height*r;
    setCenter(_video);
  }

  private function onCuePoint(info:Object):void
  {
    log("onCuePoint: "+expandAttrs(info));
  }

  private function onPlayStatus(info:Object):void
  {
    log("onPlayStatus: "+expandAttrs(info));
  }

  private function onAsyncErrorEvent(ev:AsyncErrorEvent):void
  {
    log("onAsyncErrorEvent: "+ev.error);
  }

  private function connect():void
  {
    if (_params.rtmpURL != null && !_connection.connected) {
      log("Connecting: "+_params.rtmpURL);
      _control.status.text = "Connecting...";
      _connection.connect(_params.rtmpURL);
    }
  }

  private function play():void
  {
    if (_params.streamPath != null && !_playing) {
      log("Playing: "+_params.streamPath);
      _control.playButton.busy = true;
      _control.status.text = "Starting...";
      _stream.play(_params.streamPath);
      _video.attachNetStream(_stream);
    }
  }

  private function stop():void
  {
    if (_playing) {
      _control.playButton.busy = true;
      _control.status.text = "Stopping...";
      _video.attachNetStream(null);
      _stream.close();
    }
  }

  private function setPlayState(playing:Boolean):void
  {
    if (playing) {
      if (_connection.connected) {
	play();
      } else {
	connect();
      }
    } else {
      stop();
    }
  }

}

} // package

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFieldAutoSize;
import flash.net.NetStream;
import flash.net.NetStreamInfo;
import flash.ui.Keyboard;

class VideoOverlay extends Sprite
{
  public function VideoOverlay(w:int, h:int)
  {
    graphics.beginFill(0, 0);
    graphics.drawRect(0, 0, w, h);
    graphics.endFill();
  }

  public function show(playing:Boolean):void
  {
    
  }

  public function update():void
  {
  }
}

class ControlBar extends Sprite
{
  public var status:StatusDisplay;
  public var playButton:PlayPauseButton;
  public var volumeSlider:VolumeSlider;
  public var fsButton:FullscreenButton;

  public const alphaDelta:Number = 0.1;
  private var _margin:int;
  private var _limit:int;

  public function ControlBar(width:int, size:int, margin:int=8, fullscreen:Boolean=false)
  {
    graphics.beginFill(0, 0.5);
    graphics.drawRect(0, 0, width, size+margin*2);
    graphics.endFill();

    _margin = margin;

    playButton = new PlayPauseButton(size, size);
    playButton.toPlay = true;
    addChild(playButton);

    volumeSlider = new VolumeSlider(size*2, size);
    volumeSlider.value = 1.0;
    addChild(volumeSlider);

    if (fullscreen) {
      fsButton = new FullscreenButton(size, size);
      addChild(fsButton);
    }

    var w:int = width;
    w -= (_margin+playButton.width+_margin+volumeSlider.width);
    if (fsButton != null) {
      w -= (_margin+fsButton.width);
    }
    status = new StatusDisplay(w-margin*2, size);
    addChild(status);

    resize();
  }

  private var _autohide:Boolean;
  public function get autohide():Boolean
  {
    return _autohide;
  }
  public function set autohide(value:Boolean):void
  {
    _autohide = value;
    if (!_autohide) {
      alpha = 1.0;
    }
  }

  public function resize():void
  {
    playButton.x = _margin;
    playButton.y = _margin;

    volumeSlider.x = playButton.x+playButton.controlWidth+_margin;
    volumeSlider.y = _margin;

    var x:int = width;
    if (fsButton != null) {
      x -= fsButton.controlWidth + _margin;
      fsButton.x = x;
      fsButton.y = _margin;
    }

    status.x = volumeSlider.x+volumeSlider.controlWidth+_margin;
    status.y = _margin;
  }

  public function update():void
  {
    if (_autohide) {
      if (0 < _limit) {
	_limit--;
      } else {
	alpha = Math.max((alpha - alphaDelta), 0.0);
      }
    }
  }

  public function show():void
  {
    alpha = 1.0;
    _limit = 48;
  }
}

class DebugDisplay extends Sprite
{
  private var logger:TextField;
  private var overlay:TextField;
  private var infotext:TextField;

  public var debugWidth:int;
  public var debugHeight:int;

  public function DebugDisplay(w:int, h:int)
  {
    debugWidth = w;
    debugHeight = h;

    logger = new TextField();
    logger.multiline = true;
    logger.wordWrap = true;
    logger.border = true;
    logger.width = 400;
    logger.height = 100;
    logger.background = true;
    logger.type = TextFieldType.DYNAMIC;
    addChild(logger);

    overlay = new TextField();
    overlay.multiline = true;
    overlay.width = 200;
    overlay.height = 100;
    overlay.textColor = 0xffffff;
    overlay.type = TextFieldType.DYNAMIC;
    addChild(overlay);

    infotext = new TextField();
    infotext.multiline = true;
    infotext.width = 200;
    infotext.height = 200;
    infotext.textColor = 0xffff00;
    infotext.type = TextFieldType.DYNAMIC;
    addChild(infotext);
  }

  public function log(x:String):void
  {
    logger.appendText(x+"\n");
    logger.scrollV = logger.maxScrollV;
  }

  public function update(stream:NetStream):void
  {
    var text:String;
    text = ("time: "+stream.time+"\n"+
	    "bufferLength: "+stream.bufferLength+"\n"+
	    "backBufferLength: "+stream.backBufferLength+"\n"+
	    "currentFPS: "+Math.floor(stream.currentFPS)+"\n"+
	    "liveDelay: "+stream.liveDelay+"\n");
    overlay.text = text;
    overlay.x = debugWidth - overlay.width;
    overlay.y = debugHeight - overlay.textHeight;

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
    infotext.text = text;
    infotext.x = 0;
    infotext.y = debugHeight - infotext.textHeight;
  }
}

class Control extends Sprite
{
  public var bgColor:uint = 0x448888ff;
  public var fgColor:uint = 0xcc888888;
  public var fgColorHi:uint = 0xffeeeeee;
  public var borderColor:uint = 0x88ffffff;

  public var controlWidth:int;
  public var controlHeight:int;

  public function Control(w:int, h:int)
  {
    addEventListener(Event.ADDED_TO_STAGE, onAdded);
    addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
    addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
    controlWidth = w;
    controlHeight = h;
  }

  private var _mousedown:Boolean;
  private var _mouseover:Boolean;

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
    update();
  }

  protected virtual function onMouseDown(e:MouseEvent):void 
  {
    if (_mouseover) {
      _mousedown = true;
      update();
    }
  }

  protected virtual function onMouseUp(e:MouseEvent):void 
  {
    if (_mousedown) {
      _mousedown = false;
      update();
    }
  }

  protected virtual function onMouseOver(e:MouseEvent):void 
  {
    _mouseover = true;
    update();
  }

  protected virtual function onMouseOut(e:MouseEvent):void 
  {
    _mouseover = false;
    update();
  }

  public virtual function update():void
  {
    graphics.clear();
    graphics.beginFill(bgColor, (bgColor>>>24)/255);
    graphics.drawRect(0, 0, controlWidth, controlHeight);
    graphics.endFill();
  }
}

class Button extends Control
{
  public function Button(w:int, h:int)
  {
    super(w, h);
  }

  public override function update():void
  {
    super.update();

    if (highlit) {
      graphics.lineStyle(0, borderColor, (borderColor>>>24)/255);
      graphics.drawRect(0, 0, controlWidth, controlHeight);
    }
  }
}

class Slider extends Control
{
  public static const CLICK:String = "Slider.Click";
  public static const CHANGED:String = "Slider.Changed";

  public var minDelta:int = 4;

  public function Slider(w:int, h:int)
  {
    super(w, h);
  }

  private var _x0:int;
  private var _y0:int;
  private var _changing:Boolean;

  protected override function onMouseDown(e:MouseEvent):void 
  {
    super.onMouseDown(e);
    addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    _x0 = e.localX;
    _y0 = e.localY;
    _changing = false;
  }

  protected override function onMouseUp(e:MouseEvent):void 
  {
    if (!_changing && pressed) {
      dispatchEvent(new Event(CLICK));
    }
    removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    super.onMouseUp(e);
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

class VolumeSlider extends Slider
{
  public var muteColor:uint = 0xffff0000;

  public function VolumeSlider(w:int, h:int)
  {
    super(w, h);
  }

  private var _value:Number = 0;
  public function get value():Number
  {
    return _value;
  }
  public function set value(v:Number):void
  {
    v = Math.max(0, Math.min(1, v));
    if (_value != v) {
      _value = v;
      update();
      dispatchEvent(new Event(CHANGED));
    }
  }

  private var _muted:Boolean = false;
  public function get muted():Boolean
  {
    return _muted;
  }
  public function set muted(value:Boolean):void
  {
    _muted = value;
    update();
  }
  
  protected override function onMouseDrag(e:MouseEvent):void 
  {
    var size:int = Math.min(controlWidth, controlHeight)/8;
    var w:int = (controlWidth-size*2);
    value = (e.localX-size)/w;
  }

  public override function update():void
  {
    var size:int = Math.min(controlWidth, controlHeight)/4;
    var color:uint = (highlit)? fgColorHi : fgColor;
    super.update();

    graphics.lineStyle(0, color, (color>>>24)/255);
    graphics.moveTo(size, controlHeight-size);
    graphics.lineTo(controlWidth-size, size);
    graphics.lineTo(controlWidth-size, controlHeight-size);
    graphics.lineTo(size, controlHeight-size);

    var w:int = (controlWidth-size*2);
    var h:int = (controlHeight-size*2);
    graphics.beginFill(color, (color>>>24)/255);
    graphics.moveTo(size, controlHeight-size);
    graphics.lineTo(size+_value*w, controlHeight-size-_value*h);
    graphics.lineTo(size+_value*w, controlHeight-size);
    graphics.endFill();

    if (_muted) {
      graphics.lineStyle(2, muteColor, (muteColor>>>24)/255);
      graphics.moveTo(controlWidth/2-size, controlHeight/2-size);
      graphics.lineTo(controlWidth/2+size, controlHeight/2+size);
    }
  }
}

class FullscreenButton extends Button
{
  public function FullscreenButton(w:int, h:int)
  {
    super(w, h);
  }

  private var _toFullscreen:Boolean = false;
  public function get toFullscreen():Boolean
  {
    return _toFullscreen;
  }
  public function set toFullscreen(value:Boolean):void
  {
    _toFullscreen = value;
    update();
  }

  public override function update():void
  {
    super.update();
    var size:int = Math.min(controlWidth, controlHeight)/16;
    var color:uint = (highlit)? fgColorHi : fgColor;
    var cx:int = controlWidth/2 + ((pressed)? 2 : 0);
    var cy:int = controlHeight/2 + ((pressed)? 2 : 0);

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

class PlayPauseButton extends Button
{
  public function PlayPauseButton(w:int, h:int)
  {
    super(w, h);
  }

  private var _busy:Boolean = false;
  public function get busy():Boolean
  {
    return _busy;
  }
  public function set busy(value:Boolean):void
  {
    _busy = value;
    update();
  }

  private var _toPlay:Boolean = false;
  public function get toPlay():Boolean
  {
    return _toPlay;
  }
  public function set toPlay(value:Boolean):void
  {
    _toPlay = value;
    update();
  }

  public override function update():void
  {
    super.update();
    var size:int = Math.min(controlWidth, controlHeight)/16;
    var color:uint = (highlit)? fgColorHi : fgColor;
    var cx:int = controlWidth/2 + ((pressed)? 2 : 0);
    var cy:int = controlHeight/2 + ((pressed)? 2 : 0);

    if (_busy) {
      
    } else if (_toPlay) {
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

class StatusDisplay extends Control
{
  private var _text:TextField;

  public function StatusDisplay(w:int, h:int)
  {
    super(w, h);
    _text = new TextField();
    _text.width = w;
    _text.height = h;
    _text.selectable = false;
    addChild(_text);
  }

  public function get text():String
  {
    return _text.text;
  }
  public function set text(value:String):void
  {
    _text.text = value;
  }

  public override function update():void
  {
    super.update();
    var color:uint = (highlit)? fgColorHi : fgColor;
    _text.textColor = color;
  }
}

class Params
{
  public var debug:Boolean = false;
  public var url:String = null;
  public var bufferTime:Number = 1.0;
  public var bufferTimeMax:Number = 1.0;
  public var maxPauseBufferTime:Number = 30.0;
  public var rtmpURL:String = null;
  public var streamPath:String = null;
  public var fullscreen:Boolean = false;

  public function Params(baseurl:String, obj:Object)
  {
    var i:int;

    if (obj != null) {
      // debug
      if (obj.debug) {
	debug = (parseInt(obj.debug) != 0);
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
      // fullscreen
      if (obj.fullscreen) {
	fullscreen = (parseInt(obj.fullscreen) != 0);
      }
      // url
      if (obj.url) {
	url = obj.url;
      }
    }

    if (url != null) {
      if (url.substr(0, 1) == "/") {
	// if url starts with "/", it means a relative url.
	i = baseurl.indexOf("://");
	if (0 < i) {
	  baseurl = baseurl.substring(i+3);
	  i = baseurl.indexOf("/");
	  if (i < 0) {
	    i = baseurl.length;
	  }
	  url = "rtmp://"+baseurl.substr(0, i)+url;
	}
      }
      i = url.lastIndexOf("/");
      rtmpURL = url.substr(0, i);
      streamPath = url.substr(i+1);
    }
  }
}
