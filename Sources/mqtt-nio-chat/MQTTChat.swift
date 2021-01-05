import Foundation
import Logging
import MQTTNIO
import NIO
import Darwin

struct MQTTChat {
    let command: MQTTChatCommand
    let eventLoopGroup: EventLoopGroup
    let mqttClient: MQTTClient
    let topicName: String
    let logger: Logger = {
        var logger = Logger(label: "Chat")
        logger.logLevel = .trace
        return logger
    }()

    init(command: MQTTChatCommand) {
        self.command = command
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.topicName = "MQTTNIOChat-\(self.command.topic)"
        self.mqttClient = MQTTClient(
            host: command.servername,
            port: command.port,
            identifier: "MQTTNIOChat-\(command.username)",
            eventLoopGroupProvider: .shared(eventLoopGroup),
            logger: nil//self.logger
        )
    }
    
    func syncShutdown() throws {
        try self.mqttClient.syncShutdownGracefully()
    }
    
    func addListeners() {
        self.mqttClient.addPublishListener(named: "ListenForChat") { result in
            switch result {
            case .failure:
                break
            case .success(let publishInfo):
                if publishInfo.topicName == self.topicName {
                    receiveMessage(publishInfo.payload)
                }
            }
        }
        
        self.mqttClient.addCloseListener(named: "CheckForClose") { result in
            outputAndReplacePrompt("Lost connection")
        }
    }
    
    func setup(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        // connect, subscribe and publish
        self.mqttClient.connect(cleanSession: false).flatMap { hasSession -> EventLoopFuture<Void> in
            if !hasSession {
                let subscription = MQTTSubscribeInfo(topicFilter: self.topicName, qos: .exactlyOnce)
                return self.mqttClient.subscribe(to: [subscription])
            } else {
                return eventLoop.makeSucceededFuture(())
            }
        }
        .flatMap { _ in
            self.addListeners()
            return self.sendMessage("Joined! Say Hello!")
        }
    }
    
    func sendMessage(_ message: String) -> EventLoopFuture<Void> {
        let packet = ChatPacket(from: command.username, message: message)
        var buffer = ByteBufferAllocator().buffer(capacity: 0)
        try? JSONEncoder().encode(packet, into: &buffer)
        return self.mqttClient.publish(to: self.topicName, payload: buffer, qos: .exactlyOnce)
    }
    
    func receiveMessage(_ buffer: ByteBuffer) {
        if let packet = try? JSONDecoder().decode(ChatPacket.self, from: buffer) {
            guard packet.from != command.username else { return }
            outputAndReplacePrompt("\(packet.from): \(packet.message)")
        }
    }
    
    func run() throws {
        output("Connecting to \(topicName)")
        try setup(on: eventLoopGroup.next()).wait()
        output("Connected to \(topicName)")
        while true {
            prompt()
            if let line = readLine() {
                _ = self.sendMessage(line)
            }
        }
    }

    func deleteCurrentLine() {
        fputs("\u{1b}[0G\u{1b}[K", stdout)
    }

    func output(_ string: String) {
        fputs("\(string)\n", stdout)
    }

    func prompt() {
        fputs("\(command.username): ", stdout)
        fflush(stdout)
    }

    func outputAndReplacePrompt(_ string: String) {
        deleteCurrentLine()
        output(string)
        prompt()
    }

    struct ChatPacket: Codable {
        let from: String
        let message: String
    }
}

