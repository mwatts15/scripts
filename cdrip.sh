#!/bin/sh
DEVICE=${1:-/dev/cdrom}
cdparanoia -ve -w -B -d $DEVICE 
flac *
rm *.wav
picard *.flac
