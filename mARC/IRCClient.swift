//
//  IRCClient.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import Foundation
import Network
import Combine

@MainActor
class IRCClient: ObservableObject {
    
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var messages: [IRCMessage] = []
    @Published var nickname = ""
    @Published var channels: [Channel] = []
    @Published var activeChannel: Channel?

    
    private var connection: NWConnection?
    private var buffer = Data()
    
    func connect(host: String, port: UInt16, useSSL: Bool = false, nickname: String) {
        guard !isConnecting && !isConnected else { return }
        
        self.nickname = nickname
        isConnecting = true
        let msg = parseIRCMessage("Connecting to \(host):\(port)...")
        messages.append(msg)
        
        let hostEndpoint = NWEndpoint.Host(host)
        let portEndpoint = NWEndpoint.Port(rawValue: port)!
        
        let parameters: NWParameters
        if useSSL {
            parameters = NWParameters(tls: .init())
        } else {
            parameters = .tcp
        }
        
        connection = NWConnection(host: hostEndpoint, port: portEndpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handleStateChange(state)
            }
        }
        
        connection?.start(queue: .global())
    }
    
    private func handleStateChange(_ state: NWConnection.State) {
        switch state {
        case .ready:
            isConnecting = false
            isConnected = true
            let msg = parseIRCMessage("Connected! Registering as \(nickname)...")
            messages.append(msg)
            startReceiving()
            register()
            
        case .waiting(let error):
            let msg = parseIRCMessage("Waiting: \(error.localizedDescription)")
            messages.append(msg)
            
        case .failed(let error):
            isConnecting = false
            isConnected = false
            let msg = parseIRCMessage("Connection Failed: \(error.localizedDescription)")
            messages.append(msg)
            
        case .cancelled:
            isConnected = false
            isConnecting = false
            let msg = parseIRCMessage("Disconnected")
            messages.append(msg)
            
        default:
            break
        }
    }
    
    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let data = content {
                Task { @MainActor in
                    self?.handleReceivedData(data)
                }
            }
            
            if error == nil && !isComplete {
                self?.startReceiving()
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        buffer.append(data)
        
        while let lineEnd = buffer.firstIndex(of: 0x0A) {
            var lineData = buffer[..<lineEnd]
            buffer = Data(buffer[buffer.index(after: lineEnd)...])
            
            if let last = lineData.last, last == 0x0D {
                lineData = lineData.dropLast()
            }
            
            if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                handleLine(line)
            }
        }
    }
    
    func sendRaw(_ message: String) {
        guard isConnected else { return }
        
        print(">>> \(message)")
        let data = (message + "\r\n").data(using: .utf8)!
        
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
            }
        })
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnecting = false
        isConnected = false
        messages.removeAll()
        selectChannel(nil)
    }
    
    func register() {
        sendRaw("NICK \(nickname)")
        sendRaw("User \(nickname) 0 * :mARC User")
    }
    
    private func handleLine(_ line: String){
        print("<<< \(line)")
        
        let msg = parseIRCMessage(line)
        
        if line.hasPrefix("PING") {
            let param = msg.params.first ?? ""
            sendRaw("PONG :\(param)")
        }
        
        routeMessage(msg)
    }

    private func addSystemMessage(_ text: String) {
        let msg = IRCMessage(raw: text, prefix: nil, command: "SYSTEM", params: [text])
        messages.append(msg)
    }
    
    
    private func routeMessage(_ msg: IRCMessage) {
        switch msg.command {
        case "JOIN":
            let channelName = msg.params.first ?? ""
            if msg.nick == nickname {
                let channel = Channel(name: channelName)
                channel.messages.append(msg)
                channels.append(channel)
                activeChannel = channel
            }else if let channel = findChannel(channelName){
                channel.messages.append(msg)
                if let nick = msg.nick, !channel.users.contains(ChannelUser(nick: nick)){
                    channel.users.append(ChannelUser(nick: nick))
                }
            }
        case "PART":
            let channelName = msg.params.first ?? ""
            if msg.nick == nickname {
                channels.removeAll { $0.name == channelName }
                if activeChannel?.name == channelName {
                    activeChannel = channels.first
                }
            } else if let channel = findChannel(channelName) {
                channel.messages.append(msg)
                if let nick = msg.nick {
                    channel.users.removeAll { $0.nick == nick }
                }
            }
        case "PRIVMSG":
            let target = msg.params.first ?? ""
                if target.hasPrefix("#") || target.hasPrefix("&") {
                    if let channel = findChannel(target) {
                        channel.messages.append(msg)
                        if activeChannel != channel {
                            channel.unreadCount += 1
                        }
                    }
                } else {
                    let nick = msg.nick ?? "unknown"
                    if let pm = findChannel(nick) {
                        pm.messages.append(msg)
                        if activeChannel != pm {
                            pm.unreadCount += 1
                        }
                    } else {
                        let pm = Channel(name: nick)
                        pm.messages.append(msg)
                        pm.unreadCount = 1
                        channels.append(pm)
                    }
                }
        case "QUIT":
            if let nick = msg.nick {
                   for channel in channels {
                       if channel.users.contains(where: { $0.nick == nick }) {
                           channel.messages.append(msg)
                           channel.users.removeAll { $0.nick == nick }
                       }
                   }
               }
        case "353":
            if msg.params.count >= 4 {
                    let channelName = msg.params[2]
                    let names = msg.params[3].split(separator: " ").map(String.init)
                    if let channel = findChannel(channelName) {
                        for name in names {
                            var nick = name
                            var isOp = false
                            var isVoice = false
                            
                            if nick.hasPrefix("@") {
                                isOp = true
                                nick = String(nick.dropFirst())
                            } else if nick.hasPrefix("+") {
                                isVoice = true
                                nick = String(nick.dropFirst())
                            }
                            
                            if !channel.users.contains(where: { $0.nick == nick }) {
                                channel.users.append(ChannelUser(nick: nick, isOp: isOp, isVoice: isVoice))
                            }
                        }
                        channel.sortUsers()
                    }
                }
        case "366":
            messages.append(msg)
        case "332":
            if msg.params.count >= 2 {
                let channelName = msg.params[1]
                let topic = msg.params.count > 2 ? msg.params[2] : ""
                if let channel = findChannel(channelName) {
                    channel.topic = topic
                }
            }

        case "TOPIC":
            let channelName = msg.params.first ?? ""
            let topic = msg.params.count > 1 ? msg.params[1] : ""
            if let channel = findChannel(channelName) {
                channel.topic = topic
                channel.messages.append(msg)
            }
        case "NICK":
            let oldNick = msg.nick ?? ""
            let newNick = msg.params.first ?? ""
            
            if oldNick == nickname {
                nickname = newNick
            }
            
            for channel in channels {
                if let index = channel.users.firstIndex(where: { $0.nick == oldNick }) {
                    channel.users[index].nick = newNick
                    channel.messages.append(msg)
                    channel.sortUsers()
                }
            }
        case "MODE":
            guard msg.params.count >= 2 else {
                messages.append(msg)
                return
            }
            
            let target = msg.params[0]
            
            // Only handle channel modes
            if target.hasPrefix("#") || target.hasPrefix("&") {
                if let channel = findChannel(target) {
                    channel.messages.append(msg)
                    
                    let modes = msg.params[1]
                    var modeTargets = Array(msg.params.dropFirst(2))
                    var adding = true
                    
                    for char in modes {
                        switch char {
                        case "+":
                            adding = true
                        case "-":
                            adding = false
                        case "o":
                            if let nick = modeTargets.first {
                                modeTargets.removeFirst()
                                if let index = channel.users.firstIndex(where: { $0.nick == nick }) {
                                    channel.users[index].isOp = adding
                                    channel.sortUsers()
                                }
                            }
                        case "v":
                            if let nick = modeTargets.first {
                                modeTargets.removeFirst()
                                if let index = channel.users.firstIndex(where: { $0.nick == nick }) {
                                    channel.users[index].isVoice = adding
                                    channel.sortUsers()
                                }
                            }
                        default:
                            break
                        }
                    }
                }
            } else {
                messages.append(msg)
            }
        case "KICK":
            guard msg.params.count >= 2 else { return }
            let channelName = msg.params[0]
            let kickedNick = msg.params[1]
            let reason = msg.params.count > 2 ? msg.params[2] : "No reason"
            
            if kickedNick == nickname {
                if let channel = findChannel(channelName) {
                    channel.messages.append(msg)
                }
                channels.removeAll { $0.name == channelName }
                if activeChannel?.name == channelName {
                    activeChannel = channels.first
                }
                addSystemMessage("You were kicked from \(channelName) by \(msg.nick ?? "someone"): \(reason)")
            } else if let channel = findChannel(channelName) {
                channel.messages.append(msg)
                channel.users.removeAll { $0.nick == kickedNick }
            }
        default:
            messages.append(msg)
            
        }
    }
    private func findChannel(_ name: String) -> Channel? {
        channels.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func openPrivateMessage(with nick: String) {
        if let existing = findChannel(nick) {
            activeChannel = existing
        } else {
            let pm = Channel(name: nick)
            channels.append(pm)
            activeChannel = pm
        }
    }
    
    func selectChannel(_ channel: Channel?) {
        activeChannel = channel
        channel?.unreadCount = 0
    }
}
