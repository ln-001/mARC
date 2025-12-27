//
//  ContentView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var irc = IRCClient()
    
    @State private var host = "127.0.0.1"
    @State private var port = "6667"
    @State private var useSSL = false
    @State private var nickname = "mIRCmac"
    
    @State private var inputText = ""
    
    @State private var refreshCounter = 0
    
    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            refreshCounter += 1
        }
        .frame(minWidth: 700, minHeight: 400)
    }
    
    
    var sidebarView: some View {
        let _ = refreshCounter // Force refresh
        
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
                            Label(channel.name, systemImage: channel.name.hasPrefix("#") ? "number" : "person")
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
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 150)
    }
    
    
    var detailView: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                connectionBar
                topicBar
                Divider()
                messagesView
                Divider()
                inputBar
            }
            
            if let channel = irc.activeChannel {
                Divider()
                UserListView(channel: channel) { nick in
                    irc.openPrivateMessage(with: nick)
                }
            }
        }
    }
    
    
    var connectionBar: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            TextField("Host", text: $host)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
            
            TextField("Port", text: $port)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
            
            Toggle("SSL", isOn: $useSSL)
            
            TextField("Nickname", text: $nickname)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
            
            Spacer()
            
            connectionButton
        }
        .padding(8)
    }
    
    @ViewBuilder
    var connectionButton: some View {
        if irc.isConnected {
            Button("Disconnect") {
                irc.disconnect()
            }
        } else if irc.isConnecting {
            Button("Cancel") {
                irc.disconnect()
            }
        } else {
            Button("Connect") {
                connect()
            }
        }
    }
    
    var statusColor: Color {
        if irc.isConnected { return .green }
        if irc.isConnecting { return .yellow }
        return .red
    }
    
    
    @ViewBuilder
    var topicBar: some View {
        if let channel = irc.activeChannel, !channel.topic.isEmpty {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundStyle(.secondary)
                Text(channel.topic)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
        }
    }
    
    
    var messagesView: some View {
        let _ = refreshCounter // Force refresh
        
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(currentMessages) { msg in
                        MessageView(msg: msg, myNick: irc.nickname)
                            .id(msg.id)
                    }
                }
                .padding(8)
            }
            .onChange(of: currentMessages.count) { _ in
                if let last = currentMessages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
    
    var currentMessages: [IRCMessage] {
        if let channel = irc.activeChannel {
            return channel.messages
        }
        return irc.messages
    }
    
    
    var inputBar: some View {
        HStack {
            TextField("Enter message or /command", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .onSubmit {
                    sendInput()
                }
                .disabled(!irc.isConnected)
            
            Button("Send") {
                sendInput()
            }
            .disabled(!irc.isConnected || inputText.isEmpty)
        }
        .padding(8)
    }
    
    
    func connect() {
        guard let portNum = UInt16(port) else { return }
        irc.connect(host: host, port: portNum, useSSL: useSSL, nickname: nickname)
    }
    
    func sendInput() {
        guard !inputText.isEmpty else { return }
        
        if inputText.hasPrefix("/") {
            handleCommand(inputText)
        } else if let channel = irc.activeChannel {
            irc.sendRaw("PRIVMSG \(channel.name) :\(inputText)")
            let msg = IRCMessage(
                raw: "",
                prefix: irc.nickname,
                command: "PRIVMSG",
                params: [channel.name, inputText]
            )
            channel.messages.append(msg)
        }
        
        inputText = ""
    }
    
    func handleCommand(_ input: String) {
        let withoutSlash = String(input.dropFirst())
        let parts = withoutSlash.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let command = String(parts.first ?? "").uppercased()
        let args = parts.count > 1 ? String(parts[1]) : ""
        
        switch command {
        case "JOIN", "J":
            irc.sendRaw("JOIN \(args)")
            
        case "PART", "LEAVE":
            if args.isEmpty, let channel = irc.activeChannel {
                irc.sendRaw("PART \(channel.name)")
            } else {
                irc.sendRaw("PART \(args)")
            }
            
        case "QUIT":
            irc.sendRaw("QUIT :\(args.isEmpty ? "Leaving" : args)")
            irc.disconnect()
            
        case "KICK":
            if let channel = irc.activeChannel {
                let kickParts = args.split(separator: " ", maxSplits: 1)
                if let target = kickParts.first {
                    let reason = kickParts.count > 1 ? String(kickParts[1]) : "Kicked"
                    irc.sendRaw("KICK \(channel.name) \(target) :\(reason)")
                }
            }
            
        case "MSG", "PRIVMSG":
            let msgParts = args.split(separator: " ", maxSplits: 1)
            if msgParts.count >= 2 {
                irc.sendRaw("PRIVMSG \(msgParts[0]) :\(msgParts[1])")
            }
            
        case "ME":
            if let channel = irc.activeChannel {
                irc.sendRaw("PRIVMSG \(channel.name) :\u{01}ACTION \(args)\u{01}")
                let msg = IRCMessage(
                    raw: "",
                    prefix: irc.nickname,
                    command: "ACTION",
                    params: [channel.name, args]
                )
                channel.messages.append(msg)
            }
            
        case "MODE":
            if let channel = irc.activeChannel {
                irc.sendRaw("MODE \(channel.name) \(args)")
            }
            
        case "NICK":
            irc.sendRaw("NICK \(args)")
            
        case "TOPIC":
            if let channel = irc.activeChannel {
                if args.isEmpty {
                    irc.sendRaw("TOPIC \(channel.name)")
                } else {
                    irc.sendRaw("TOPIC \(channel.name) :\(args)")
                }
            }
            
        case "RAW":
            irc.sendRaw(args)
            
        default:
            irc.sendRaw(withoutSlash)
        }
    }
}

#Preview {
    ContentView()
}
