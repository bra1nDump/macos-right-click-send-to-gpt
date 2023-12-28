//
//  OverlayPanelView.swift
//  CaptureSample
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI
import Carbon

/////// INITIALLY COPIED OVER FROM SHARE SHOT
struct RightClickExtraMenuView: View {
    let selectedText: String
    let sendToChrome: (String) async -> Bool
    let cleanupAndClose: () -> Void

    @ObservedObject private var eventMonitors = KeyboardAndMouseEventMonitors()

    // TODO: Handle dark mode
    // TODO: Add state representing different sending to chrome states

    enum SendOption {
        case append
        case appendAndSend
    }

    func sendAndClose(option: SendOption) {
        Task {
            var magicPayload: String
            switch option {
            case .append:
                magicPayload = "vscodeAddText:\(selectedText)"
            case .appendAndSend:
                magicPayload = "vscodeSendMessage:\(selectedText)"
            }

            let success = await sendToChrome(magicPayload)
            cleanupAndClose()
        }
    }
    
    var body: some View {
        VStack {
            Spacer()

            // Create another vertical stack to make the menu look like the native NSMenu
            VStack {
                MenuItem(text: "[ChatGPT] Append to message", keyboardShortcut: "⌘ + ;") {
                    sendAndClose(option: .append)
                }
                MenuItem(text: "[ChatGPT] Append and send", keyboardShortcut: "⌘ + ⌥ + ;") {
                    sendAndClose(option: .appendAndSend)
                }
            }
            .background(Color.white)
            .cornerRadius(5)
            .shadow(radius: 5)
        }
            // Debugging layout
            .background(Color.gray.opacity(0.2))
            .onDisappear {
                print("on dissapear")
                eventMonitors.stopMonitoringEvents()
            }
            .onAppear {
                print("on appear")
                
                // We might be able to move this up to the view init code
                eventMonitors.startMonitoringEvents(
                    onEscape: {
                        // Manually release monitors to release the view - otherwise the monitors hold on to reference to the Window (somehow) I am assuming and the window does not get ordered out
                        eventMonitors.stopMonitoringEvents()
                        cleanupAndClose()
                    }
                )
            }
    }

    @ViewBuilder
    func MenuItem(text: String, keyboardShortcut: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.black)
            Spacer()
            Text(keyboardShortcut)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white)
        .onTapGesture {
            action()
        }
    }
}

class KeyboardAndMouseEventMonitors: ObservableObject {
    private var monitors: [Any?] = []

    // TODO: Pretty sure we can just move these to init
    func startMonitoringEvents(onEscape: @escaping () -> Void) {
        print("startMonitoringEvents")
        
        // Ensure no duplicate monitors
        stopMonitoringEvents()

        monitors = [
            // Catch Escape by watching all keyboard presses
            // I believe because the window were and is not becoming key 
            // We need to use a global monitor
            NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                if Int(event.keyCode) == kVK_Escape {
                    print("escape")
                    onEscape()
                }
            },
        ]
    }

    func stopMonitoringEvents() {
        for monitor in monitors {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        monitors.removeAll()
    }
    
    // Why is this not being called?!
    deinit {
        stopMonitoringEvents()
    }
}