The application is a macOS app that adds a context menu item 'Send to ChatGPT' when user right clicks on the selected text anywhere in their mac. If the user selects the item it will send the selected text to the chrome instance, given chrome is running and has the extension installed. Chrome extension will open chat.openai.com and paste the text into the chat box.


Found potentially related mac application that adds context menu items to finder on right click.
https://github.com/samiyuru/custom-finder-right-click-menu/blob/master/FinderMenuItems/RightClickActions.swift

It's distributed is an extension, which is what I assume I need to do as well.

I would then need to have the same system as vscode helpfuldev has for linking vscode to chrome. Chrome can only be connecting to the server, not starting one, so I would have to run the app in the background and have it listen for connections from chrome. As the user right clicks, our app will use the existing chrome connection to send the selected.

# Only thing that would work is accessibility APIs
[notebook](.task/sessions/1-Wed.task)
+ Show an additional menu in addition to the default menu


```swift
import Cocoa
import ApplicationServices
```

Then, you can define a function to check if the necessary accessibility permissions are granted:

```swift
func checkAccessibilityPermissions() -> Bool {
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [checkOptPrompt: true]
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)

    return accessibilityEnabled
}
```

This function will return `true` if the necessary permissions are granted, and `false` otherwise. If the permissions are not granted, it will prompt the user to grant them.

Next, you can define a function to create a `CGEventTap`:

```swift
func createEventTap() {
    let eventMask = (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.rightMouseUp.rawValue)
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

    CFRunLoopRun()
}
```

This function creates an event tap that listens for right mouse down and up events (i.e., right-click events). When such an event is detected, it calls the `eventTapCallback` function, which you need to define:

```swift
let eventTapCallback: CGEventTapCallBack = { proxy, type, event, refcon in
    if [.rightMouseDown, .rightMouseUp].contains(CGEventType(rawValue: type.rawValue)!) {
        if let selectedText = getSelectedText() {
            print("Selected text: \(selectedText)")
            // Here you can handle the selected text and show your context menu
        }
    }

    return Unmanaged.passRetained(event)
}
```

This callback function gets the selected text whenever a right-click event is detected and prints it. You can replace the print statement with your own code to handle the selected text and show your context menu.


Function to get the selected text:

```swift
func getSelectedText() -> String? {
    // Get the system-wide accessibility element
    let systemWideElement = AXUIElementCreateSystemWide()

    // Get the current focused element
    var focusedElement: AnyObject?
    let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

    guard error == .success else {
        print("Could not get focused element")
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
```

Finally, you can use these functions in your application's main function:

```swift
func applicationDidFinishLaunching(_ aNotification: Notification) {
    if checkAccessibilityPermissions() {
        createEventTap()
    } else {
        print("Accessibility permissions not granted")
    }
}
```

# Alternative
Alternatively we could use global monitor + screen record for right click right? Lower level permissions

# Unknowns
- How to find where the menu is displayd? - We probably want to show our menu right above the default menu