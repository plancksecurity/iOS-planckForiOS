#!/bin/bash

translationdir=../pEp-Translate/

mytmpdir=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

cp $translationdir/*.xliff $mytmpdir

rm -fr $mytmpdir
