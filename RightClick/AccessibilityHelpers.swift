//  AccessibilityHelpers.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/27/23.
//

import AXSwift
import Foundation
import AppKit

/**
    Negative for position means that the menu is sean on a secondary display.

    The `AXFrame` attribute returns a CGRect that represents the frame of the UI element in screen coordinates. 
    The origin of this coordinate system is the top-left corner of the main screen, and it extends towards the right (increasing x) and downwards (increasing y).
    
    When you have multiple monitors, the coordinate system can extend into negative values. This happens when a monitor is arranged to the left or above the main monitor in the display settings. 
    In such cases, the top-left corner of that monitor will have negative x (if it's to the left) or negative y (if it's above) values.
    
    The negative values you're seeing are likely because the menu is appearing on a monitor that is arranged to the left of the main monitor.
*/
func getFocusedMenuFrame() -> CGRect? {
    guard let uiApp = getActiveApplication() else {
        print("no uiApp :), it could have been terminated or the process identifier is smaller than zero")
        return nil
    }

    guard let windows: [UIElement] = try? uiApp.windows() else {
        print("no windows :)")
        return nil
    }

    for window in windows {
        if let menuFrame = recurseUntilWeFindAMenu(element: window) {
            return menuFrame
        }
    }
    return nil
}

/// Alternative way to get the selected text. I believe this actually works correctly unlike the previous code, that does not work for Chrome, vscode and some other web based apps.
// TODO: Rewrite in terms of simpler code using AXSwift
func getSelectedTextWidthSystemWideElement() -> String? {
    // Get the system-wide accessibility element
    let systemWideElement = AXUIElementCreateSystemWide()

    // Get the current focused element
    var focusedElement: AnyObject?
    let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

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


fileprivate func getActiveApplication() -> Application? {
    guard let application = NSWorkspace.shared.frontmostApplication else {
        print("no active app. I don't think this should ever happen, pretty sure if there's no other application selected it will always be finder.")
        return nil
    }

    print("localizedName: \(String(describing: application.localizedName)), processIdentifier: \(application.processIdentifier)")

    return Application(application)
}

/// Recursive function to find the menu in the given UIElement
fileprivate func recurseUntilWeFindAMenu(element: UIElement) -> CGRect? {
    // Submenus we'll have the same role but will be descendants of a AXMenu
    // Since we return the first menu, this shouldn't be a problem
    if let role: String = try? element.attribute(.role),
       role == "AXMenu" {

        if let menuPosition: CGRect = try? element.attribute(.frame) {
            return menuPosition
        } else {
            print("We have found a menu but it doesn't have a frame attribute. Should never happen.")
        }
    }

    guard let children: [UIElement] = try? element.arrayAttribute(.children) else {
        return nil
    }

    for child in children {
        if let menuFrame = recurseUntilWeFindAMenu(element: child) {
            return menuFrame
        }
    }
    return nil
}
