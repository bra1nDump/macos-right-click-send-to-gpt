////
////  SocketServer.swift
////  RightClick
////
////  Created by Kirill Dubovitskiy on 12/24/23.
////
//
//import Foundation
//import Vapor
//
//func startVapor() -> (String) -> Void {
//    let app = Application()
//    defer { app.shutdown() }
//    
//    
//    
//    var lastWebSocketConnected: WebSocket?
//
////    app.http.server.configuration.port = 3233
//
//    app.webSocket("/") { req, ws in
//        // Connected WebSocket.
//        print("YEEEY")
//        print(ws)
//        
//        lastWebSocketConnected = ws
//    }
//
//    // Don't block
//    Task {
//        try? await app.execute()
//    }
//    
//    return {
//        (message: String) in
//        print("sending: \(message)")
//        lastWebSocketConnected?.send(message)
//    }
//}
//
//
