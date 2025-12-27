//
//  MessagesView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//
import SwiftUI

struct MessagesView: View {
    let messages: [IRCMessage]
    let myNick: String
    let refreshCounter: Int
    
    var body: some View {
        let _ = refreshCounter
        
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(messages) { msg in
                        MessageView(msg: msg, myNick: myNick)
                            .id(msg.id)
                    }
                }
                .padding(8)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}
