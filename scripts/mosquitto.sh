#!/bin/sh
HOME=$(dirname $0)

docker run -p 1883:1883 -v $(pwd)/"$HOME":/mosquitto/config eclipse-mosquitto


