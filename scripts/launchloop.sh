#!/bin/sh

while [ 1 != 2 ]; do
		echo "Launching daemon from launchloop..."
		./em/daemon.rb $* 2>&1
		sleep 3
done
