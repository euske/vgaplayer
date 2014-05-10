@set FLEX_HOME=%UserProfile%\flex_sdk_4.6
java -jar %FLEX_HOME%\lib\mxmlc.jar +flexlib=%FLEX_HOME%\frameworks -static-rsls -compiler.source-path=./src -o .\bin\vgaplayer.swf .\src\Main.as
@if errorlevel 1 (
 pause
 exit /b 
)
