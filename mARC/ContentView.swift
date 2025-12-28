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
    
    @AppStorage("host") private var host = ""
    @AppStorage("port")  private var port = ""
    @AppStorage("useSSL")  private var useSSL = false
    @AppStorage("nickname")  private var nickname = ""
    @AppStorage("saslUsername") private var saslUsername = ""
    @State private var saslPassword = ""
  
    
    @State private var inputText = ""
    
    @State private var refreshCounter = 0
    
    var body: some View {
        NavigationSplitView {
            SidebarView(irc: irc, refreshCounter: refreshCounter)
        } detail: {
            detailView
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            refreshCounter += 1
        }
        .frame(minWidth: 700, minHeight: 400)
    }
    
    var detailView: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ConnectionBar(
                    irc: irc,
                    host: $host,
                    port: $port,
                    useSSL: $useSSL,
                    nickname: $nickname,
                    saslUsername: $saslUsername,
                    saslPassword: $saslPassword,
                    onConnect: connect
                )
                
                if let channel = irc.activeChannel, !channel.topic.isEmpty {
                    TopicBar(topic: channel.topic)
                }
                
                Divider()
                
                MessagesView(
                    messages: currentMessages,
                    myNick: irc.nickname,
                    refreshCounter: refreshCounter
                )
                
                Divider()
                
                InputBar(
                    inputText: $inputText,
                    isConnected: irc.isConnected,
                    onSend: sendInput
                )
            }
            
            if let channel = irc.activeChannel {
                Divider()
                UserListView(channel: channel) { nick in
                    irc.openPrivateMessage(with: nick)
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
        
    func connect() {
        guard let portNum = UInt16(port) else { return }
        
        self.nickname = nickname.trimmingCharacters(in: .whitespaces)
        self.saslPassword = saslPassword
            self.saslUsername = saslUsername.trimmingCharacters(in: .whitespaces)
        
        irc.connect(host: host, port: portNum, useSSL: useSSL, nickname: nickname, saslUsername: saslUsername, saslPassword: saslPassword)
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
