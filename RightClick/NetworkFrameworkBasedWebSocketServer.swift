//
//  NetworkFrameworkBasedWebSocketServer.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/24/23.
//

import Foundation
import Network

class NetworkBasedWebSocketServer {
    private var listener: NWListener?
    private var connections: [NWConnection] = []

    func start() -> (String) -> Void {
        // TODO: Currently does not support
        do {
            let params = NWParameters(tls: nil)
            params.allowLocalEndpointReuse = true
            params.includePeerToPeer = true
            let websocketOptions = NWProtocolWebSocket.Options()
            websocketOptions.autoReplyPing = true
            params.defaultProtocolStack.applicationProtocols.insert(websocketOptions, at: 0)
            listener = try NWListener(using: params, on: 3232)
        } catch {
            fatalError("Failed to create listener: \(error)")
        }

        listener?.newConnectionHandler = { [weak self] newConnection in
            print("New connection")
            self?.connections.append(newConnection)
            self?.setupConnection(newConnection)
            newConnection.start(queue: .main)

            newConnection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("Connection ready")
                case .failed(let error):
                    print("Connection failed: \(error)")
                    self?.removeConnection(newConnection)
                default:
                    break
                }
            }
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Server started and listening")
            case .failed(let error):
                print("Server did not start: \(error)")
            default:
                break
            }
        }

        listener?.start(queue: .main)
        
        return {
            (message: String) in
            // Format expected by extension
            let data = Data("vscodeAddText:\(message)".utf8)
            print("Sending \(message), connection count: \(self.connections.count)")
            
            
            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(identifier: "message", metadata: [metadata])
            
            self.connections.forEach { connection in
                connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
                    if let error = error {
                        print("Send error: \(error)")
                        self.removeConnection(connection)
                    }
                }))
            }
        }
    }

    private func setupConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Connection ready")
            case .failed(let error):
                print("Connection failed: \(error)")
                self?.removeConnection(connection)
            default:
                break
            }
        }

        connection.receiveMessage { [weak self] (data, context, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8)
                print("Received message: \(message ?? "")")
            }
            if let error = error {
                print("Receive error: \(error)")
                self?.removeConnection(connection)
                return
            }
            self?.setupConnection(connection)
        }
    }

    private func removeConnection(_ connection: NWConnection) {
        connection.cancel()
        if let index = connections.firstIndex(where: { $0 === connection }) {
            connections.remove(at: index)
        }
    }
}
