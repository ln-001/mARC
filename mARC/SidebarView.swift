//
//  SidebarView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var irc: IRCClient
    let refreshCounter: Int
    
    var body: some View {
        let _ = refreshCounter
        
        return List {
            Section("Server") {
                Button {
                    irc.selectChannel(nil)
                } label: {
                    Label("Status", systemImage: "server.rack")
                }
                .buttonStyle(.plain)
                .listRowBackground(irc.activeChannel == nil ? Color.accentColor.opacity(0.3) : Color.clear)
            }
            
            Section("Channels") {
                ForEach(irc.channels) { channel in
                    Button {
                        irc.selectChannel(channel)
                    } label: {
                        HStack {
                            Label(channel.name.replacingOccurrences(of: "#", with: ""), systemImage: channel.name.hasPrefix("#") ? "number" : "person")
                            Spacer()
                            if channel.unreadCount > 0 {
                                Text("\(channel.unreadCount)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(irc.activeChannel == channel ? Color.accentColor.opacity(0.3) : Color.clear)
                    .contextMenu{
                        if channel.name.hasPrefix("#") || channel.name.hasPrefix("&"){
                            Button("Leave Channel"){
                                irc.partChannel(channel.name)
                            }
                        }else{
                            Button("Close"){
                                irc.closePrivateMessage(channel)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 150)
    }
}
