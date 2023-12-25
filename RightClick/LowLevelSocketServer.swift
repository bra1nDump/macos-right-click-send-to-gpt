//
//  LowLevelSocketServer.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/24/23.
//

import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket

class WebSocketServer {
    private var lastWebSocket: WebSocketConnection?
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    func start() -> (String) -> Void {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: .init((upgraders: [self.upgrader()], completionHandler: { _ in }))).flatMap {
                    channel.pipeline.addHandler(WebSocketHandler { self.lastWebSocket = $0 })
                }
            }
        
        do {
            let channel = try bootstrap.bind(host: "localhost", port: 3232).wait()
            print("Server started and listening on \(channel.localAddress!)")
        } catch {
            print("Server did not start: \(error)")
        }
        
        return { [weak self] message in
            print("Sending: \(message)")
            self?.lastWebSocket?.send(text: message)
        }
    }
    
    private func upgrader() -> NIOWebSocketServerUpgrader {
        return NIOWebSocketServerUpgrader(shouldUpgrade: { channel, req in
            return channel.eventLoop.makeSucceededFuture([:])
        }, upgradePipelineHandler: { channel, req in
            return channel.pipeline.addHandler(WebSocketHandler { self.lastWebSocket = $0 })
        })
    }
}

class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    private let connectionEstablished: (WebSocketConnection) -> Void
    
    init(connectionEstablished: @escaping (WebSocketConnection) -> Void) {
        self.connectionEstablished = connectionEstablished
    }
    
    func channelActive(context: ChannelHandlerContext) {
        let connection = WebSocketConnection(channel: context.channel)
        connectionEstablished(connection)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)
        // Handle WebSocket frame
    }
}

class WebSocketConnection {
    private let channel: Channel
    
    init(channel: Channel) {
        self.channel = channel
    }
    
    func send(text: String) {
        let frame = WebSocketFrame(fin: true, opcode: .text, data: ByteBuffer(string: text))
        _ = channel.writeAndFlush(frame)
    }
}
