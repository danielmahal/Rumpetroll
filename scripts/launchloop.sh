#!/bin/bash

PIDFILE=/tmp/tadpoleLaunchloop.pid
echo $$ > $PIDFILE

while [ `cat $PIDFILE` == $$ ]; do
		echo "Launching daemon from launchloop..."
		./em/daemon.rb $* 2>>./data/error.out
		sleep 1
done

echo "Launchloop ended..."
