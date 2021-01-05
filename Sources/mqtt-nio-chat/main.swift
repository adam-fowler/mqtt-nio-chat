import ArgumentParser

struct MQTTChatCommand: ParsableCommand {
    @Option(name: .shortAndLong, help: "Topic name")
    var topic: String

    @Option(name: .shortAndLong, help: "User name")
    var username: String

    @Option(name: .shortAndLong, help: "Server name")
    //var servername: String = "localhost"
    //var servername: String = "test.mosquitto.org"
    var servername: String = "broker.hivemq.com"

    @Option(name: .shortAndLong, help: "Server port")
    var port: Int = 1883

    func run() throws {
        try MQTTChat(command: self).run()
    }
}

MQTTChatCommand.main()
