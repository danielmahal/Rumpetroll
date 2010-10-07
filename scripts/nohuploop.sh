#!/bin/sh

LOGFILE=data/daemon.out
nohup ./scripts/launchloop.sh $* >> $LOGFILE &

LOOPPID=$!

echo "** Starting launchloop on PID $LOOPPID. Logging to $LOGFILE. **"
echo "  NB! You should make sure only launchloop with PID $LOOPPID is running."
