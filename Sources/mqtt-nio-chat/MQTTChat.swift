import Foundation
import Logging
import MQTTNIO
import NIO

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
            logger: self.logger
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
            print("Lost connection")
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
            print("\(packet.from): \(packet.message)")
        }
    }
    
    func run() throws {
        print("Connecting to \(topicName)")
        try setup(on: eventLoopGroup.next()).wait()
        print("Connected to \(topicName)")
        while true {
            while let line = readLine() {
                _ = self.sendMessage(line)
                //print(mqttClient.pipeline!)
            }
        }
    }

    struct ChatPacket: Codable {
        let from: String
        let message: String
    }
}
