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

func getSelectedText() -> String? {
    guard let uiApp = getActiveApplication() else {
        print("no uiApp :), it could have been terminated or the process identifier is smaller than zero")
        return nil
    }

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
        return selectedText
    }
    
    return nil
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
