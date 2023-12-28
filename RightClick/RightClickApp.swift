//  RightClickApp.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//

import SwiftUI
import AXSwift
import Cocoa

@main
struct RightClickApp {
    static func main() {
        let appDelegate = AppDelegate()
        let application = NSApplication.shared
        application.delegate = appDelegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    
    var rightClickExtraMenuWindow: RightClickExtraMenuWindow? = nil

    var sendToChrome: ((String) async -> Bool)! = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self
        
        // Start the server and get a closure to send messages to the "Send to Gpt" chrome extension
        sendToChrome = NetworkBasedWebSocketServer().sendToCurrentConnection

        // WARNING: The prompt will not be showing in sandbox applications!
        // Even manually setting accessibility permissions in System Preferences did not work.
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            print("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }
        
        startListeningForRightMouseUp()

        // TODO: At keyboard shortcut hot keys
    }

    func onRightClickUp(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        guard let selectedText = getSelectedText() else {
            print("No selected text, it doesn't make sense to show the menu")
            return Unmanaged.passRetained(event)
        }

        print("Selected text: \(selectedText)")

        // TODO: Check that we actually need those task nonsense and repeated checks for menus
        // and the menu is not immediately available
        Task {
            let start = DispatchTime.now()

            // TODO: Add bundle and application names so we can later configure different behavior for apps
            var focusedMenuFrame: CGRect?
            while (
                // 200ms max
                DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds < 200_000_000
            ) {
                focusedMenuFrame = getFocusedMenuFrame()
                if focusedMenuFrame != nil {
                    print("Found focused menu frame: \(focusedMenuFrame!)")
                    break
                }

                // 50ms
                try await Task.sleep(nanoseconds: 50_000_000)
            }

            guard let menuFrame = focusedMenuFrame else {
                print("No focused menu frame, exiting")
                return
            }
            
            // Now we both have the selected text as well as the menu frame. We can show the menu.
            if let existingWindow = rightClickExtraMenuWindow {
                // Note: For some reason I needed to remove the panel's view from super view but not close the panel
                // WHAT'S GOING ON: I have no idea why it wants me to use await here!
                await existingWindow.close()
            }

            rightClickExtraMenuWindow = await RightClickExtraMenuWindow(
                nativeMenuFrame: menuFrame,
                selectedText: selectedText,
                sendToChrome: self.sendToChrome
            )
        }

        return Unmanaged.passRetained(event)
    }
}

func startListeningForRightMouseUp() {
    let eventMask = (1 << CGEventType.rightMouseUp.rawValue)
    guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap, 
                                            place: .headInsertEventTap, 
                                            options: .defaultTap, 
                                            eventsOfInterest: CGEventMask(eventMask), 
                                            callback: staticEventTapCallback as CGEventTapCallBack, 
                                            userInfo: nil) else {
        print("Failed to create event tap")
        exit(1)
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
}

// Static class members also cannot be used as callbacks
func staticEventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    return AppDelegate.shared.onRightClickUp(proxy: proxy, type: type, event: event, refcon: refcon)
}

