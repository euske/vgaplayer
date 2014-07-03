#!/bin/sh
JAVA=java
FLEX_HOME=${FLEX_HOME:-$HOME/flex_sdk_4.6}
MXMLC="$JAVA -jar $FLEX_HOME/lib/mxmlc.jar +flexlib=$FLEX_HOME/frameworks"

$MXMLC -static-rsls -o ./bin/vgaplayer.swf -compiler.source-path=./src/ ./src/Main.as
