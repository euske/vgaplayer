VGA Player
==========

It's an open source player for Adobe Flash Media Server streaming (RTMP stream).

Demo: http://euske.github.io/vgaplayer/demo.html

Typical usage:

    <embed src="play.swf" width="100%" height="99%" 
         play="true" 
         allowScriptAccess="sameDomain"
         allowFullScreen="true"
         type="application/x-shockwave-flash"
         FlashVars="url=rtmp://rtmp.example.com&amp;fullscreen=1"
         pluginspage="http://www.adobe.com/go/getflashplayer" />

FlashVars Parameters:

  It takes a form of `FlashVars="name=value&amp;name=value&amp;..."`

  * url: RTMP URL. (e.g. "rtmp://example.com/live" or "/app/live")
  * debug: Indicates if the debug console is displayed. (1: on, 0: off)
  * fullscreen: Indicates if the fullscreen button is shown. (1: on, 0: off)
  * smoothing: Indicates if the video smoothing is turned on. (1: on, 0: off)
  * bufferTime: Stream buffering time. (default: 1.0 sec)
  * bufferTimeMax: Maximum stream buffering time. (default: 1.0 sec)
  * bgColor: Background color. (default: "#000000")
  * buttonBgColor: Button background color. The upper 8 bits are for alpha. (default: "#448888ff")
  * buttonFgColor: Button foreground color. (default: "#cc888888")
  * buttonHiColor: Button highlighting color. (default: "#ffeeeeee")
  * buttonBorderColor: Button border color. (default: "#88ffffff")
  * volumeMutedColor: Color used when the volume is muted. (default: "#ffff0000")
  * imageUrl: Background image URL.

Terms and Conditions
--------------------

(This is so-called MIT/X License)

Copyright (c) 2014  Yusuke Shinyama <yusuke at cs dot nyu dot edu>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
