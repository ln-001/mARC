//
//  InputBarView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import SwiftUI

struct InputBar: View {
    @Binding var inputText: String
    let isConnected: Bool
    var onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("Enter message or /command", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .onSubmit {
                    onSend()
                }
                .disabled(!isConnected)
            
            Button("Send") {
                onSend()
            }
            .disabled(!isConnected || inputText.isEmpty)
        }
        .padding(8)
    }
}
