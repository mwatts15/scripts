#!/bin/sh
DEVICE=${1:-/dev/cdrom}
cdparanoia -ve -w -B -d $DEVICE 
flac *.wav
rm *.wav
picard *.flac
