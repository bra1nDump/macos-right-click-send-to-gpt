//  RightClickApp.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/19/23.
//

import SwiftUI

import Cocoa
import SwiftUI

import AXSwift

@main
struct RightClickApp {
    static func main() {
        let appDelegate = AppDelegate()
        let application = NSApplication.shared
        application.delegate = appDelegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

func getSelectedText(uiApp: Application) -> String? {
    
    // TODO: Check if this is even needed? I think getting selection should be totally fine
    
    // The Swifty API does not expose these attributes
    AXUIElementSetAttributeValue(uiApp.element, "AXManualAccessibility" as CFString, kCFBooleanTrue)
    AXUIElementSetAttributeValue(uiApp.element, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
    
    // Get focused element
    var focusedElement: UIElement?
    focusedElement = try? uiApp.attribute(.focusedUIElement)

    if (focusedElement == nil) {
        focusedElement = try? uiApp.attribute(.focusedWindow)
    }
    
    if let selectedText: String = try? focusedElement?.attribute(.selectedText) {
        NSLog("selectedText: \(String(describing: selectedText))")
        return selectedText
    }
    
    return nil
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    var popover: NSPopover?
    var statusBarItem: NSStatusItem?
    var contextMenu: NSMenu?
    
    var nonFocusingPanel: OverlayPanel!

    func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        if [.rightMouseDown, .rightMouseUp].contains(CGEventType(rawValue: type.rawValue)!) {
            if let selectedText = getSelectedText() {
                print("Selected text: \(selectedText)")
                // Here you can handle the selected text and show your context menu
            } else {
                print("nothing")
            }
        }

        return Unmanaged.passRetained(event)
    }
    
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.shared = self
        
        // Start vapor and get back a way to send to clients
//        let sendToChrome = startVapor()
        let sendToChrome = NetworkBasedWebSocketServer().start()

        // Create tap without accessibility - lets try
        
        guard UIElement.isProcessTrusted(withPrompt: true) else {
            NSLog("No accessibility API permission, exiting")
            NSRunningApplication.current.terminate()
            return
        }
        
        print("we guci")
         createEventTap()
    
        
        Task {
            while (true) {
                print("looopy")
                if let application = NSWorkspace.shared.frontmostApplication {

                    NSLog("localizedName: \(String(describing: application.localizedName)), processIdentifier: \(application.processIdentifier)")
                    let uiApp = Application(application)
                    
                    

                    // Now that I have the selected element, I want to find the NSMenu thats visible and get its cooridnates. I will need that later.
//                        let menu: UIElement! = try! uiApp!.attribute(.shownMenu)
//                        NSLog("menu: \(String(describing: menu))")
//                        let menuPosition: CGRect! = try! menu?.attribute(.frame)
//                        NSLog("menuPosition: \(String(describing: menuPosition))")
//


                    
                    func recurseUntilWeFindAMenu(element: UIElement) {
                        // Use windows() on uiApp and next use arrayAttribute with .children on each window to get the children of each window. Then use .role on each child to see if it is a menu. If it is, then use .frame to get the coordinates of the menu. If it is not a menu, then use .children on that child to get its children and repeat the process.
                        if let role: String = try? element.attribute(.role),
                           role == "AXMenu" {
                            NSLog("role: \(String(describing: role))")
                            
                            // Submenus have AXMenuItem children - ignore them :D
                            // Actually - just return once we found a menu :D
                            
                                if let attributes = try? element.attributes(),
                                   let attributeDictionary = try? element.getMultipleAttributes(attributes) {
                                    print("menu attributes: \(attributeDictionary)")
                                }
                                
                                //                                 The `AXFrame` attribute returns a CGRect that represents the frame of the UI element in screen coordinates. The origin of this coordinate system is the top-left corner of the main screen, and it extends towards the right (increasing x) and downwards (increasing y). 

                                // However, when you have multiple monitors, the coordinate system can extend into negative values. This happens when a monitor is arranged to the left or above the main monitor in the display settings. In such cases, the top-left corner of that monitor will have negative x (if it's to the left) or negative y (if it's above) values.

                                // So, the negative values you're seeing are likely because the menu is appearing on a monitor that is arranged to the left of the main monitor.
                                if let menuPosition: CGRect = try? element.attribute(.frame) {
                                    NSLog("menuPosition: \(String(describing: menuPosition))")

                                    // If our custom menu is nil - create it and present right above the menuPosition. Do a dummy menu with hello world item and see if it works
                                    // Otherwise do nothing
                                    // We can see how Maccy's code does this - they also popup a menu at position
                                    if self.contextMenu == nil {
                                        // Create the menu
                                        let menu = NSMenu()
                                        menu.addItem(NSMenuItem(title: "Hello World", action: nil, keyEquivalent: ""))
                                        self.contextMenu = menu
                                    }
                                    
                                    // Dismisses the current menu :(
                                    // Show the popover
//                                    self.popover?.show(relativeTo: menuPosition, of: nil, preferredEdge: .maxY)
                                    
                                    
                                    DispatchQueue.main.async {
                                        print("panel")
                                        // The presentation needs to be from both a right click + menu, not just menu
                                        self.nonFocusingPanel = OverlayPanel(contentRect: menuPosition.offsetBy(dx: -100, dy: -100), sendToChrome: sendToChrome)
                                    }
                                }
                                
                                return
                        }

                        guard let children: [UIElement] = try? element.arrayAttribute(.children) else {
                            return
                        }
//                        NSLog("children: \(String(describing: children))")

                        for child in children {
                            recurseUntilWeFindAMenu(element: child)
                        }
                    }
                    
                    let windows: [UIElement]! = try! uiApp!.windows()
//                    NSLog("windows: \(String(describing: windows))")

                    for window in windows {
                        recurseUntilWeFindAMenu(element: window)
                    }
                } else {
                    print("no active app :)")
                }
                
//                try? printAccessibilityTree()
                
                // In xcode specifically this does not work Hmmmm
                print("loool")
                
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        

        
    }

    // https://github.com/tmandry/AXSwift/tree/main
    // https://github.com/lujjjh/node-selection
    //   Chrome does not work, neither does VSCode
    //   Setings chrome://accessibility/
    //   They are on
    //   Speak seleciton is on - it can pick up selection from both chrome and vscode
    //   Alternatively I can use copy to extract the text and restore clipboard later
    //
    //   This might not be available without enabling explicitly. The copy to clipboard does not suffer the same problem
    // When I toggle 'Speak Selection' in system settings and refresh chrome 
    // https://chromium.googlesource.com/chromium/src/+/main/docs/accessibility/overview.md


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

struct CustomMenuView: View {
    let sendToChrome: (String) -> Void
    
    var body: some View {
        VStack {
            Button("Hello World") {
                print("LOOOOOOO>")
                
                if let selection = getSelectedText() {
                    // Send to our connection
                    sendToChrome(selection)
                }
            }
                .padding()
        }
        .cornerRadius(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
    }
}

/////// COPIED OVER FROM CAPTURE EXAMPLE
// This class took me 2 days to get somewhat right - the flags are obviously very important.
//
// It accomplishes the following behavior:
// - From anywhere I will be able to use a keyboard shortcut to create a overlay over my entire screen
// - It will block interactions with existing applications while the user is selecting the range to screenshot
// - We will use this overly to draw the cursor and the selection rectangle (delegated to the
//
// The tricky parts:
// - We want the application not to take focus, so everything else on screen remains exacly the same
// - It allows to get keyboard events
//
// Most of this was eye balled and copied from pixel picker / Maccy projects
class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        // lets try to prevent dismissing menu
        get { return false }
    }
    var screenshotPreview: NSImageView?
    // Initializer for OverlayPanel
    init(contentRect: NSRect, sendToChrome: @escaping (String) -> Void) {
        // Style mask passed here is key! Changing it later will not have the same effect!
        super.init(contentRect: contentRect, styleMask: .nonactivatingPanel, backing: .buffered, defer: true)

        // Not quite sure what it does, sounds like it makes this float over other models
        self.isFloatingPanel = true
        
        // How does the window behave across collections (I assume this means ctrl + up, spaces managment)
        // We might need to further update the styleMask above to get the right combination, but good enough for now
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenAuxiliary]

        // Special behavior for models
        self.worksWhenModal = true

        // Track the mouse
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
        self.backgroundColor = .blue.withAlphaComponent(0.4)
        
        let nsHostingContentView = NSHostingView(rootView: CustomMenuView(sendToChrome: sendToChrome))
        self.contentView = nsHostingContentView
        
        // Additional window setup
//        makeKeyAndOrderFront(self)
        // TRY
        
        orderFront(self)
    }

    private func cleanupAndClose() {
        // To make sure its removed - the swiftUI view still seems to remain in memory - strange
        self.contentView = nil
        self.close()
    }
}


/// UNUSED
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
