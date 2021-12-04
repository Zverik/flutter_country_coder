#!/bin/bash
BORDERS=../lib/src/data/borders.dart
TMP_BORDERS=/tmp/borders.json
curl 'https://raw.githubusercontent.com/ideditor/country-coder/main/src/data/borders.json' > $TMP_BORDERS
echo "final String bordersRaw = '''" > $BORDERS
cat $TMP_BORDERS >> $BORDERS
echo "''';" >> $BORDERS
rm $TMP_BORDERS
