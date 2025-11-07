//
//  WindowModifier.swift
//  CleanMyMac
//
//  Window configuration modifier for translucent effect
//

import SwiftUI
import AppKit

struct TranslucentWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor())
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func translucentWindow() -> some View {
        modifier(TranslucentWindowModifier())
    }
}

