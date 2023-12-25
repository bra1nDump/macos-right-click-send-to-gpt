//
//  NetworkFrameworkBasedWebSocketServer.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/24/23.
//

import Foundation
import Network

class NetworkBasedWebSocketServer {
    enum ServerStartupResult: Equatable {
        // This error is expected since we have multiple servers using same port range
        case addressInUseError
        case otherError(String)
        case allGucci
    }

    enum State {
        case bindingToPortInRange(start: Int, end: Int)
        case bindingToAllPortsInRangeFailed
        case listening(onPort: Int, listener: NWListener, activeConnection: NWConnection?)
    }

    var state: State

    // TODO: Handle restart when server is killed somehow - maybe after computer goes to sleep or something?
    // I would firt prioritize adding basic logging to see if thats even happening
    init() {
        let start = 3228
        let end = start + 10
        state = .bindingToPortInRange(start: start, end: end)

        Task {
            for port in start...end {
                if let listener = await startListener(on: port, onNewConnection: {
                    [weak self] connection in
                    self?.onNewConnection(connection: connection)
                }) {
                    state = .listening(onPort: port, listener: listener, activeConnection: nil)
                    return
                }
            }

            state = .bindingToAllPortsInRangeFailed
        }
    }

    func onNewConnection(connection: NWConnection) {
        print("New connection")
        
        switch state {
        case .listening(let port, let listener, _):
            state = .listening(onPort: port, listener: listener, activeConnection: connection)
        default:
            break
        }
        
        setupConnection(connection)
        connection.start(queue: .main)
    }

    func startListener(on port: Int, onNewConnection: @Sendable @escaping (NWConnection) -> Void) async -> NWListener? {
        let params = NWParameters(tls: nil)
        params.allowLocalEndpointReuse = true
        params.includePeerToPeer = true
        let websocketOptions = NWProtocolWebSocket.Options()
        websocketOptions.autoReplyPing = true
        params.defaultProtocolStack.applicationProtocols.insert(websocketOptions, at: 0)
        
        guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: UInt16(port))!) else {
            return nil
        }
        
        listener.newConnectionHandler = onNewConnection

        let startupResult: ServerStartupResult = await withCheckedContinuation { continuation in
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Server started and listening on port \(port)")
                    continuation.resume(returning: .allGucci)
                case .failed(.posix(POSIXErrorCode.EADDRINUSE)):
                    print("Port in use \(port)")
                    continuation.resume(returning: .addressInUseError)
                case .failed(let error):
                    continuation.resume(returning: .otherError("\(error)"))
                default:
                    continuation.resume(returning: .otherError("unknown error"))
                }
            }
            listener.start(queue: .main)
        }

        if startupResult == .allGucci {
            return listener
        } else {
            return nil
        }
    }

    func sendToCurrentConnection(message: String) async -> Bool {        
        switch state {
        case .listening(_, _, let activeConnection):
            guard let activeConnection = activeConnection else {
                print("No active connection to send to")
                return false
            }
            
            // Format expected by extension
            let data = Data("vscodeAddText:\(message)".utf8)
            print("Sending \(message)")
            
            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(identifier: "message", metadata: [metadata])

            return await withCheckedContinuation { continuation in
                activeConnection.send(content: data, contentContext: context, isComplete: true, completion:
                    .contentProcessed({ error in
                        if let error = error {
                            print("Send error: \(error)")
                            self.removeConnection(activeConnection)
                            continuation.resume(returning: false)
                        } else {
                            print("Send success")
                            continuation.resume(returning: true)
                        }
                    })
                )
            }
        default:
            print("No active connection, not sending")
            return false
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
        switch state {
        case .listening(let port, let listener, _):
            state = .listening(onPort: port, listener: listener, activeConnection: nil)
        default:
            break
        }
    }
}
