#!/bin/sh
DEVICE=${1:-/dev/cdrom}
RHOST=${CDRIP_RHOST:?Must have a CDRIP_RHOST value set to specify the machine where the cdrip actually happens}
dir=`date +%Y%m%d%S`
mkdir -p $HOME/music/$dir
ssh $RHOST "mkdir -p $dir"
ssh $RHOST "cd $dir && cdparanoia -ve -w -B -d $DEVICE"
ssh $RHOST "cd $dir && flac *.wav"
ssh $RHOST "cd $dir && rm *.wav"
scp -r "$RHOST:$dir/*" $HOME/music/$dir
cd $HOME/music/$dir && find -name '*.flac' | xargs picard
