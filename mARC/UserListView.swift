//
//  UserListView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import SwiftUI

struct UserListView: View {
    @ObservedObject var channel: Channel
    var onUserDoubleClick: ((String) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Users (\(channel.users.count))")
                .font(.headline)
                .padding(8)
            
            Divider()
            
            List(channel.users) { user in
                Text(user.displayName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(userColor(user))
                    .onTapGesture(count: 2) {
                        onUserDoubleClick?(user.nick)
                    }
            }
            .listStyle(.plain)
        }
        .frame(width: 150)
    }
    
    func userColor(_ user: ChannelUser) -> Color {
        if user.isOp { return .red }
        if user.isVoice { return .blue }
        return .primary
    }
}
