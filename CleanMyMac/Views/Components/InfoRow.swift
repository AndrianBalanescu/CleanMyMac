//
//  InfoRow.swift
//  CleanMyMac
//
//  Info row component for displaying key-value pairs
//

import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
}

