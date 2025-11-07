//
//  GlassBackgroundView.swift
//  CleanMyMac
//
//  Reusable glass effect modifier/view
//

import SwiftUI

struct GlassBackground: ViewModifier {
    let material: Material
    
    init(material: Material = .ultraThinMaterial) {
        self.material = material
    }
    
    func body(content: Content) -> some View {
        content
            .background(material)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassBackground(material: Material = .ultraThinMaterial) -> some View {
        modifier(GlassBackground(material: material))
    }
}

struct GlassCard: View {
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .glassBackground()
            .padding()
    }
}

struct GlassButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

