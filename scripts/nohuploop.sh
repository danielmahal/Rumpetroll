#!/bin/sh

LOGFILE=data/daemon.out
nohup ./scripts/launchloop.sh $* >> $LOGFILE &
echo "** Starting launchloop on PID $! **"
echo "Tailing $LOGFILE. Please make sure we have regular output:"
tail -f ./data/daemon.out