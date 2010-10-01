#!/bin/sh

while [ 1 != 2 ]; do
		echo "Launching daemon..."
		./em/daemon.rb
		sleep 1
done
