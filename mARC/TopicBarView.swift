//
//  TopicBarView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//


import SwiftUI

struct TopicBar: View {
    let topic: String
    
    var body: some View {
        HStack {
            Image(systemName: "text.quote")
                .foregroundStyle(.secondary)
            Text(topic)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
    }
}
