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
import flash.external.ExternalInterface;
import flash.system.Security;
import baseui.Style;
import baseui.Slider;
import baseui.MenuItemEvent;

//  Main 
//
public class Main extends Sprite
{
  private const STARTING:String = "STARTING";
  private const STARTED:String = "STARTED";
  private const STOPPING:String = "STOPPING";
  private const STOPPED:String = "STOPPED";
  private const PAUSED:String = "PAUSED"; // only used for non-remoting streams.
  
  private var _params:Params;
  private var _video:Video;
  private var _overlay:OverlayButton;
  private var _control:ControlBar;
  private var _debugdisp:DebugDisplay;
  private var _imageLoader:Loader;

  private var _streamPath:String;
  private var _remoting:Boolean; // true if connected via RTMP or FMS.
  private var _connection:NetConnection;
  private var _stream:NetStream;
  private var _videoMetaData:Object;
  private var _state:String;

  // Main()
  public function Main()
  {
    var info:LoaderInfo = LoaderInfo(this.root.loaderInfo);
    _params = new Params(info.parameters);
    
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
    _overlay.style = _params.style;
    _overlay.addEventListener(MouseEvent.CLICK, onOverlayClick);
    addChild(_overlay);

    _control = new ControlBar(_params.fullscreen, _params.menu);
    _control.style = _params.style;
    _control.playButton.addEventListener(MouseEvent.CLICK, onPlayPauseClick);
    _control.volumeSlider.addEventListener(Slider.CLICK, onVolumeSliderClick);
    _control.volumeSlider.addEventListener(Slider.CHANGED, onVolumeSliderChanged);
    _control.seekBar.addEventListener(Slider.CHANGED, onSeekBarChanged);
    if (_control.popupMenu != null) {
      _control.popupMenu.container = this;
      _control.popupMenu.addEventListener(MenuItemEvent.CHOOSE, onMenuItemChoose);
    }
    if (_control.fsButton != null) {
      _control.fsButton.toFullscreen = (stage.displayState == StageDisplayState.NORMAL);
      _control.fsButton.addEventListener(MouseEvent.CLICK, onFullscreenClick);
    }
    addChild(_control);

    _debugdisp = new DebugDisplay();
    _debugdisp.visible = _params.debug;
    addChild(_debugdisp);

    addEventListener(Event.ADDED_TO_STAGE, onAdded);
    addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    stage.addEventListener(Event.RESIZE, onResize);
    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    resize();

    log("FlashVars:", expandAttrs(info.parameters));
    log("url:", _params.url);
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

    if (ExternalInterface.available) {
      // Allowing security domains. 
      // Not sure if this is the right way...
      var domain:String = (Security.pageDomain == null)? "*" : Security.pageDomain;
      log("ExternalInterface: allowing: "+domain);
      Security.allowDomain(domain);
      ExternalInterface.addCallback("VGAPlayerAddMenuItem", externalAddMenuItem);
      ExternalInterface.addCallback("VGAPlayerConnect", externalConnect);
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
    if (url.indexOf("://") < 0) {
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

  private function onAdded(e:Event):void
  {
    init();
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
      var nc:NetConnection = NetConnection(ev.target);
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
      _control.seekBar.isStatic = !_remoting;
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
    } else {
      _control.statusDisplay.visible = true;
      _control.seekBar.duration = 0;
      _control.seekBar.visible = false;
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

  private function onMenuItemChoose(e:MenuItemEvent):void
  {
    log("onMenuItemChoose:", e.item.value);
    
    if (ExternalInterface.available) {
      ExternalInterface.call("VGAPlayerOnMenuChoose", e.item.value);
    }
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
    case PAUSED:
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
    if (_streamPath != null && _stream != null) {
      updateStatus(STARTING);
      log("Starting:", _streamPath, start);
      _stream.play(_streamPath, start);
    }
  }

  private function stopPlaying():void
  {
    if (_stream != null) {
      if (_remoting) {
	log("Stopping");
	updateStatus(STOPPING);
	_stream.close();
      } else {
	updateStatus(PAUSED);
	_stream.pause();
      }
    }
  }

  private function init():void
  {
    log("init");

    // Notify the browser if possible.
    if (ExternalInterface.available) {
      ExternalInterface.call("VGAPlayerOnLoad");
    }

    if (_params.autoplay) {
      connect(_params.url);
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

  private function externalAddMenuItem(label:String, value:String=null):void
  {
    log("externalAddMenuItem: "+label+", "+value);
    if (_control.popupMenu != null) {
      _control.popupMenu.addTextItem(label, value);
    }
  }

  private function externalConnect(url:String):void
  {
    stopPlaying();
    connect(url);
  }

  public function connect(url:String):void
  {
    if (_connection.connected) {
      _connection.close();
    }
    if (url != null && !_connection.connected) {
      url = getBaseURL(url);
      if (url.substr(0, 5) == "rtmp:") {
	var i:int = url.lastIndexOf("/");
	_streamPath = url.substr(i+1);
	_remoting = true;
	url = url.substr(0, i);
      } else {
	_streamPath = url;
	_remoting = false;
	url = null;
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
	  connect(_params.url);
	}
      }
      break;
    case PAUSED:
      if (playing) {
	if (_stream != null) {
	  _stream.resume();
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

/// Private classes below.

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.net.NetStream;
import flash.net.NetStreamInfo;
import baseui.Style;

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
  public var menu:Boolean = false;
  public var smoothing:Boolean = false;
  public var start:Number = 0.0;
  public var autoplay:Boolean = true;

  public var bgColor:uint = 0x000000;
  public var style:Style = new Style();
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
      // menu
      if (obj.menu) {
	menu = parseBoolean(obj.menu);
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
	style.bgColor = parseColor(obj.buttonBgColor);
      }
      // buttonFgColor
      if (obj.buttonFgColor) {
	style.fgColor = parseColor(obj.buttonFgColor);
      }
      // buttonHiFgColor
      if (obj.buttonHiFgColor) {
	style.hiFgColor = parseColor(obj.buttonHiFgColor);
      }
      // buttonHiBgColor
      if (obj.buttonHiBgColor) {
	style.hiBgColor = parseColor(obj.buttonHiBgColor);
      }
      // buttonBorderColor
      if (obj.buttonBorderColor) {
	style.borderColor = parseColor(obj.buttonBorderColor);
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
