//
//  GetSelectedText.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/23/23.
//


import AppKit
import Foundation
import ApplicationServices

// Global set of apps to manually enable accessibility
let appsManuallyEnableAx: Set<String> = ["com.google.Chrome", "org.mozilla.firefox"]

func checkAccessibilityPermissions(prompt: Bool) -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): prompt]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

func toString(_ nsString: NSString) -> String {
    return String(nsString)
}

func getFrontProcessID() -> pid_t {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
        return 0
    }
    return frontmostApplication.processIdentifier
}

func getProcessName(pid: pid_t) -> String? {
    guard let application = NSRunningApplication(processIdentifier: pid) else {
        return nil
    }
    return application.executableURL?.lastPathComponent
}

func getBundleIdentifier(pid: pid_t) -> String? {
    guard let application = NSRunningApplication(processIdentifier: pid) else {
        return nil
    }
    return application.bundleIdentifier
}


func getFocusedElement(pid: pid_t) -> AXUIElement? {
    func _getFocusedElement(pid: pid_t) -> AXUIElement? {
        let application = AXUIElementCreateApplication(pid)

        // Enable accessibility settings if needed
        if let bundleIdentifier = getBundleIdentifier(pid: pid), appsManuallyEnableAx.contains(bundleIdentifier) {
            AXUIElementSetAttributeValue(application, "AXManualAccessibility" as CFString, kCFBooleanTrue)
            AXUIElementSetAttributeValue(application, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
        }

        
        var focusedElement: AXUIElement?
        var genericRef: UnsafeMutablePointer<CFTypeRef?>
        
        genericRef = withUnsafeMutablePointer(to: &focusedElement) {
            $0.withMemoryRebound(to: CFTypeRef?.self, capacity: 1) { $0 }
        }
        var error = AXUIElementCopyAttributeValue(application, kAXFocusedUIElementAttribute as CFString, genericRef)
        if error != .success {
            print("getFocusedElement failing")
            error = AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute as CFString, genericRef)
        }
        // Here focusedElement is always nil
        print("focusedElement: \(focusedElement)")

        return focusedElement
    }

    // TODO: - Bring back - this is for chrome
//    if let focusedElement = _getFocusedElement(pid: pid) {
//        touchDescendantElements(focusedElement, maxDepth: 8)
//        return _getFocusedElement(pid: pid)
//    }
    
    return _getFocusedElement(pid: pid)
    
//    return nil
}

func attributesAsStrings(element: AXUIElement) throws -> [String] {
    var names: CFArray?
    let error = AXUIElementCopyAttributeNames(element, &names)

    if error == .noValue || error == .attributeUnsupported {
        return []
    }

    guard error == .success else {
        throw error
    }

    // We must first convert the CFArray to a native array, then downcast to an array of
    // strings.
    return names! as [AnyObject] as! [String]
}

// Debugging purposes
func printElementInfo(_ element: AXUIElement?, depth: Int) {
    guard let element = element, depth > 0 else {
        return
    }

    var value: CFTypeRef?
    var error = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
    if error != .success {
        print("failed to get role")
    }
    
    print(try? attributesAsStrings(element: element))

    var attributeNames: CFArray?
    error = AXUIElementCopyAttributeNames(element, &attributeNames)
    if error == .success {
        print("Got attribute names")
        if let attributeNames = attributeNames as? [String]  {
            print("Cast guci")
            for attributeName in attributeNames {
                var value: CFTypeRef?
                if AXUIElementCopyAttributeValue(element, attributeName as CFString, &value) == .success, let value = value {
                    print("\(String(repeating: " ", count: depth * 2))\(attributeName): \(value)")
                }
            }
        } else {
            print("Cast failed")
        }
    } else {
        print("failed to get attribute names")
    }

    // This is because AXUIElementCopyAttributeValue accepts a generic CFTypeRef
    var children: CFArray?
    var childrenRef: UnsafeMutablePointer<CFTypeRef?>
    
    childrenRef = withUnsafeMutablePointer(to: &children) {
        $0.withMemoryRebound(to: CFTypeRef?.self, capacity: 1) { $0 }
    }

    error = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, childrenRef)
    // Here maybe I should also read AXWindowsAttributes for applications?
    
    
    if error == .success, let children = children as? [AXUIElement] {
        for child in children {
            printElementInfo(child, depth: depth + 1)
        }
    }
}



struct ProcessInfo {
    var pid: pid_t
    var name: String?
    var bundleIdentifier: String?
}

struct Selection {
    var text: String
    var process: ProcessInfo
}

func getSelectionText(pid: pid_t) throws -> String {
    let application = AXUIElementCreateApplication(pid)
    printElementInfo(application, depth: 2)
    
    guard let focusedElement = getFocusedElement(pid: pid) else {
        throw NSError(domain: "SelectionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No focused element"])
    }

//    printElementInfo(application, depth: 2)

    if let selectedText = findSelectedText(focusedElement) {
        return selectedText
    } else {
        throw NSError(domain: "SelectionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No valid selection"])
    }
}

func getSelection() throws -> Selection {
    let pid = getFrontProcessID()
    if pid == 0 {
        throw NSError(domain: "SelectionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No front process"])
    }
    
    print("process: \(getProcessName(pid: pid) ?? "??")")

    let text = try getSelectionText(pid: pid)
    let processInfo = ProcessInfo(pid: pid, name: getProcessName(pid: pid), bundleIdentifier: getBundleIdentifier(pid: pid))
    return Selection(text: text, process: processInfo)
}

func printAccessibilityTree() throws {
    let pid = getFrontProcessID()
    if pid == 0 {
        throw NSError(domain: "SelectionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No front process"])
    }
    
    print("process: \(getProcessName(pid: pid) ?? "??")")

    let application = AXUIElementCreateApplication(pid)
    printElementInfo(application, depth: 2)
}

////// UNUSEDDD


func touchDescendantElements(_ element: AXUIElement?, maxDepth: Int) {
    print("touchDescendantElements")
    guard let element = element, maxDepth > 0 else {
        return
    }

    // This is because AXUIElementCopyAttributeValue accepts a generic CFTypeRef
    var children: CFArray?
    var childrenRef: UnsafeMutablePointer<CFTypeRef?>
    
    // Maybe I can use the write inside the
    childrenRef = withUnsafeMutablePointer(to: &children) {
        $0.withMemoryRebound(to: CFTypeRef?.self, capacity: 1) { $0 }
    }

    let error = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, childrenRef)
    if error != .success {
        return
    }

    for i in 0..<min(CFArrayGetCount(children), 8) {
        if let child = CFArrayGetValueAtIndex(children!, i) {
            let element = child.load(as: AXUIElement.self)
            touchDescendantElements(element, maxDepth: maxDepth - 1)
        }
    }
}


func findSelectedText(_ element: AXUIElement?) -> String? {
    guard let element = element else {
        print("no element")
        return nil
    }

    var value: CFTypeRef?
    if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value) == .success {
        if let value = value {
            return value as? String
        }
    }

    // This is because AXUIElementCopyAttributeValue accepts a generic CFTypeRef
    var children: CFArray?
    var childrenRef: UnsafeMutablePointer<CFTypeRef?>
    
    childrenRef = withUnsafeMutablePointer(to: &children) {
        $0.withMemoryRebound(to: CFTypeRef?.self, capacity: 1) { $0 }
    }

    let error = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, childrenRef)
    if error == .success, let children = children as? [AXUIElement] {
        for child in children {
            if let selectedText = findSelectedText(child) {
                return selectedText
            }
        }
    }

    return nil
}
