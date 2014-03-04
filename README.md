VGA Player
==========

It's an open source viewer for Adobe Flash Media Server streaming (RTMP stream).

Typical usage:

  <embed src="play.swf" width="100%" height="99%" 
	 play="true" 
	 allowScriptAccess="sameDomain"
	 allowFullScreen="true"
	 type="application/x-shockwave-flash"
	 FlashVars="url=http://rtmp.example.com&amp;fullscreen=1"
	 pluginspage="http://www.adobe.com/go/getflashplayer" />

FlashVars Parameters:

  * url: RTMP URL. (e.g. "rtmp://example.com/live" or "/app/live")
  * debug: Indicates if the debug console is displayed. (1: on, 0: off)
  * fullscreen: Indicates if the fullscreen button is shown. (1: on, 0: off)
  * bufferTime: Stream buffering time. (default: 1.0 sec)
  * bufferTimeMax: Maximum stream buffering time. (default: 1.0 sec)
  * bgColor: Background color.
  * buttonBgColor: Button background color.
  * buttonFgColor: Button foreground color.
  * buttonHiColor: Button highlighting color.
  * buttonBorderColor: Button border color.
  * volumeMutedColor: Color used when the volume is muted.

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
