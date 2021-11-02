import Foundation
import Logging
import MQTTNIO
import NIO
import Darwin

struct MQTTChatClientError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

struct MQTTChatClient {
    let command: MQTTChatCommand
    let mqttClient: MQTTClient
    let topicName: String
    let logger: Logger = {
        var logger = Logger(label: "Chat")
        logger.logLevel = .trace
        return logger
    }()
    let closePromise: EventLoopPromise<Void>

    init(command: MQTTChatCommand) {
        self.command = command
        self.topicName = "MQTTNIOChat-\(self.command.topic)"
        self.mqttClient = MQTTClient(
            host: command.servername,
            port: command.port,
            identifier: "MQTTNIOChat-\(command.username)",
            eventLoopGroupProvider: .createNew,
            logger: nil//self.logger
        )
        self.closePromise = mqttClient.eventLoopGroup.next().makePromise()
    }
    
    func syncShutdown() throws {
        try self.mqttClient.syncShutdownGracefully()
    }
    
    func run() throws {
        print("Connecting to \(self.command.topic)")
        let setupFuture = setup()
        setupFuture.cascadeFailure(to: closePromise)
        setupFuture.whenSuccess { _ in
            print("Connected to \(self.command.topic)")
            DispatchQueue.global().async {
                while true {
                    self.prompt()
                    if let line = readLine() {
                        _ = self.sendMessage(line)
                    }
                }
            }

        }

        do {
            // wait on closePromise
            try self.closePromise.futureResult.wait()

            // disconnect and shutdown
            try self.mqttClient.disconnect().wait()
            try self.mqttClient.syncShutdownGracefully()
        } catch {
            deleteCurrentLine()
            print("Error: \(error)")
        }
    }

    func setup() -> EventLoopFuture<Void> {
        // connect, subscribe and publish joined message
        self.mqttClient.connect(cleanSession: true).flatMap { hasSession -> EventLoopFuture<Void> in
            let subscription = MQTTSubscribeInfo(topicFilter: self.topicName, qos: .exactlyOnce)
            return self.mqttClient.subscribe(to: [subscription]).map { _ in }
        }
        .flatMap { _ in
            self.addListeners()
            return self.sendMessage("Joined!")
        }
    }
    
    func addListeners() {
        self.mqttClient.addPublishListener(named: "ListenForChat") { result in
            switch result {
            case .failure(let error):
                self.closePromise.fail(error)
            case .success(let publishInfo):
                if publishInfo.topicName == self.topicName {
                    receiveMessage(publishInfo.payload)
                }
            }
        }

        self.mqttClient.addCloseListener(named: "CheckForClose") { result in
            self.closePromise.fail(MQTTChatClientError(message: "Lost connection"))
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
    
    func deleteCurrentLine() {
        print("\u{1b}[0G\u{1b}[K", terminator: "")
    }

    func prompt() {
        print("\(command.username): ", terminator: "")
        fflush(stdout)
    }

    func outputAndReplacePrompt(_ string: String) {
        deleteCurrentLine()
        print(string)
        prompt()
    }

    struct ChatPacket: Codable {
        let from: String
        let message: String
    }
}

