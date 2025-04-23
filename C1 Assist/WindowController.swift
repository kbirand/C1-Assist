import SwiftUI
import AppKit

class WindowController: NSObject {
    static let shared = WindowController()
    
    // Keys for UserDefaults
    private let windowFrameKey = "windowFrame"
    
    // Save the window position and size
    func saveWindowState(_ window: NSWindow) {
        let frameString = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameString, forKey: windowFrameKey)
    }
    
    // Restore the window position and size
    func restoreWindowState(_ window: NSWindow) {
        if let frameString = UserDefaults.standard.string(forKey: windowFrameKey) {
            let frame = NSRectFromString(frameString)
            // Ensure the window is visible on any available screen
            if NSScreen.screens.contains(where: { $0.frame.intersects(frame) }) {
                window.setFrame(frame, display: true)
            }
        }
    }
}

// SwiftUI modifier to apply window persistence
struct WindowStatePersistence: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowStateHandler())
    }
}

// Helper view to access the NSWindow
struct WindowStateHandler: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        // Use DispatchQueue to ensure the window is available
        DispatchQueue.main.async {
            if let window = view.window {
                // Restore window state when created
                WindowController.shared.restoreWindowState(window)
                
                // Add notification observer for window closing
                NotificationCenter.default.addObserver(
                    forName: NSWindow.willCloseNotification,
                    object: window,
                    queue: nil) { _ in
                        WindowController.shared.saveWindowState(window)
                    }
                
                // Add notification observer for window moving/resizing
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: window,
                    queue: nil) { _ in
                        WindowController.shared.saveWindowState(window)
                    }
                
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didMoveNotification,
                    object: window,
                    queue: nil) { _ in
                        WindowController.shared.saveWindowState(window)
                    }
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// Extension to make the modifier easier to use
extension View {
    func persistWindowState() -> some View {
        modifier(WindowStatePersistence())
    }
}
