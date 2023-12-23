//
//  RightClickApp.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//

import SwiftUI

import Cocoa
import SwiftUI

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
    var statusBarItem: NSStatusItem?
    var contextMenu: NSMenu = NSMenu()

    func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        if [.rightMouseDown, .rightMouseUp].contains(CGEventType(rawValue: type.rawValue)!) {
            if let selectedText = getSelectedText() {
                print("Selected text: \(selectedText)")
                // Here you can handle the selected text and show your context menu
            }
        }

        return Unmanaged.passRetained(event)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self

        // Create tap without accessibility - lets try
        createEventTap()

        if checkAndRequestAccessibilityPermissions() {
            // createEventTap()
        } else {
            print("Accessibility permissions not granted.")
        }
    }

    // https://github.com/tmandry/AXSwift/tree/main
    // https://github.com/lujjjh/node-selection
    //   Chrome does not work, neither does VSCode
    //   Setings chrome://accessibility/
    //   They are on
    //   Speak seleciton is on - it can pick up selection from both chrome and vscode
    //   Alternatively I can use copy to extract the text and restore clipboard later
    // https://chromium.googlesource.com/chromium/src/+/main/docs/accessibility/overview.md
    func getSelectedText() -> String? {
        // Get the system-wide accessibility element
        let systemWideElement = AXUIElementCreateSystemWide()

        // Get the current focused element
        var focusedElement: AnyObject?
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        /** Fails with:
            case cannotComplete = -25204

            The function cannot complete because messaging failed in some way or because the application with which the function is communicating is busy or unresponsive. 
        */
        guard error == .success else {
            print("Could not get focused element \(error)")
            return nil
        }

        // Get the selected text from the focused element
        var selectedText: AnyObject?
        let error2 = AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)

        guard error2 == .success else {
            print("Could not get selected text")
            return nil
        }

        return selectedText as? String
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // https://developer.apple.com/forums/thread/707680
    // Input Monitoring privileges CGPreflightListenEventAccess
    func checkAndRequestAccessibilityPermissions() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)

        return accessibilityEnabled
    }

    func createEventTap() {
        let eventMask = (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.rightMouseUp.rawValue)
        let eventTapCallback: CGEventTapCallBack = staticEventTapCallback
        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap, 
                                               place: .headInsertEventTap, 
                                               options: .defaultTap, 
                                               eventsOfInterest: CGEventMask(eventMask), 
                                               callback: eventTapCallback, 
                                               userInfo: nil) else {
            print("Failed to create event tap")
            exit(1)
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
}

// Static class members also cannot be used as callbacks
func staticEventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    return AppDelegate.shared.eventTapCallback(proxy: proxy, type: type, event: event, refcon: refcon)
}
