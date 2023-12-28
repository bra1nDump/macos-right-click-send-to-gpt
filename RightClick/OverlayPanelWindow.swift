//
//  OverlayPanelWindow.swift
//  RightClick
//
//  Created by Kirill Dubovitskiy on 12/27/23.
//

import AppKit
import SwiftUI

/////// CONFIGURATION COPIED OVER FROM SHARE SHOT
class RightClickExtraMenuWindow: NSPanel {
    override var canBecomeKey: Bool {
        // lets try to prevent dismissing menu
        get { return false }
    }

    var screenshotPreview: NSImageView?

    // Initializer for OverlayPanel
    init(nativeMenuFrame: NSRect, selectedText: String, sendToChrome: @escaping (String) async -> Bool) {
        // Compute the frame for the window
        // I think we can just overestimate the height and place the view at the very bottom
        // We should not overestimate much because if the menu appears up top we will not be able to place the window above it: We cannot place windows outside of the screen, so it will be shifted down.
        // A lot of the times we will be struggling to place the menudue to space constraints, for example because of the abundance of extensions in my vscode it takes up almost the entire screen height.
        // The window will be transparent anyway
        // The width should be the same as the native menu
        // Our window's bottom should be aligned with the native menu's top with a padding of 10

        // Note: Not sure why, but it seems like by default the coordinate system is the same as in iOS, so the origin is at the top left. 
        // That strange I was always under the impression that the origin is at the bottom left on macOS. 
        // https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/CoordinateSystem.html
        // It appears that the accessibility API provides the coordinates in the iOS like coordinate system, but placing windows actually happens in the macOS coordinate system.
        let padding: CGFloat = 10
        let extraMenuHeightAndThenSomeLol: CGFloat = 70
        let contentRect = NSRect(
            x: nativeMenuFrame.minX,
            // Git current screen height and subtract the height of the menu and the padding
            // The screen will be available unless we're running on a server, in which case we would not have even gotten to this point
            y: NSScreen.main!.frame.height - nativeMenuFrame.minY +  padding,
            width: nativeMenuFrame.width,
            height: extraMenuHeightAndThenSomeLol
        )

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
        
        let view = RightClickExtraMenuView(
            selectedText: selectedText,
            sendToChrome: sendToChrome,
            cleanupAndClose: cleanupAndClose
        )
        let nsHostingContentView = NSHostingView(rootView: view)
        self.contentView = nsHostingContentView

        // Do not become key to avoid taking focus from other key window
        orderFront(self)
    }

    private func cleanupAndClose() {
        // To make sure its removed - the swiftUI view still seems to remain in memory - strange
        self.contentView = nil
        self.close()
    }
}

