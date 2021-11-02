#!/bin/sh
HOME=$(dirname $0)

docker run -d -p 1883:1883 -v $(pwd)/"$HOME":/mosquitto/config eclipse-mosquitto


