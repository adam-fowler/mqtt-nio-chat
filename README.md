# MQTT NIO Chat

Small example of using MQTT NIO to write a chat client.

## To run

The sample is setup to use a local MQTT server. There is a [script](scripts/mosquitto.sh) to run the Mosquitto MQTT server in Docker.

The sample uses ANSI escape codes to move the cursor and clear lines. These do not work inside the Xcode console so it is better to run the sample from the command line. When running you need to supply your username and the topic you are subscribing to as command line parameters.

```bash
swift run MQTTNIOChat --username <name> -topic <topic>   
```

## Public MQTT servers

If you don't have Docker or would like to test the client on another server than one run locally you can use the `--server` and `--port` command line parameters to set what server you use. Remember if you use a public server like `test.mosquitto.org` or `broker.hivemq.com` everyone can see everything you publish. 
