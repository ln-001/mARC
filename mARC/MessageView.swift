//
//  MessageView.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import SwiftUI

struct MessageView: View {
    let msg: IRCMessage
    let myNick: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("[\(msg.formattedTime)]")
                .foregroundStyle(.secondary)
            
            content
        }
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
    }
    
    @ViewBuilder
    var content: some View {
        switch msg.command {
        case "PRIVMSG":
            //Regular message: <nick> message
            let nick = msg.nick ?? "???"
            let text = msg.params.last ?? ""
            
                if text.hasPrefix("\u{01}ACTION ") && text.hasSuffix("\u{01}") {
                    let action = String(text.dropFirst(8).dropLast())
                    Text("* \(nick) \(action)")
                        .foregroundStyle(.purple)
                } else {
                    HStack(spacing: 0) {
                        Text("<")
                        Text(nick)
                            .foregroundStyle(nick == myNick ? .blue : .orange)
                        Text("> ")
                        Text(text)
                    }
                }
        case "JOIN":
            let nick = msg.nick ?? "???"
            let channel = msg.params.first ?? ""
            Text("→ \(nick) joined \(channel)")
                .foregroundStyle(.green)
            
        case "PART":
            let nick = msg.nick ?? "???"
            let channel = msg.params.first ?? ""
            Text("← \(nick) left \(channel)")
                .foregroundStyle(.orange)
            
        case "QUIT":
            let nick = msg.nick ?? "???"
            let reason = msg.params.first ?? ""
            Text("← \(nick) quit (\(reason))")
                .foregroundStyle(.orange)
            
        case "NOTICE":
            let text = msg.params.last ?? ""
            Text("[\(msg.nick ?? "Notice")] \(text)")
                .foregroundStyle(.purple)
            
        case "SYSTEM":
            Text("*** \(msg.params.first ?? "")")
                .foregroundStyle(.secondary)
            
        case "ACTION":
            let nick = msg.nick ?? msg.prefix ?? "???"
            let text = msg.params.last ?? ""
            Text("* \(nick) \(text)")
                .foregroundStyle(.purple)
        case "NICK":
            let oldNick = msg.nick ?? "???"
            let newNick = msg.params.first ?? "???"
            Text("\(oldNick) is now known as \(newNick)")
                .foregroundStyle(.teal)
        case "MODE":
            let target = msg.params.first ?? ""
            let modes = msg.params.dropFirst().joined(separator: " ")
            Text("\(msg.nick ?? "Server") sets mode \(modes) on \(target)")
                .foregroundStyle(.secondary)
        case "KICK":
            let channel = msg.params.first ?? ""
            let kicked = msg.params.count > 1 ? msg.params[1] : "???"
            let reason = msg.params.count > 2 ? msg.params[2] : ""
            Text("\(kicked) was kicked from \(channel) by \(msg.nick ?? "???") (\(reason))")
                .foregroundStyle(.red)
        default:
            if let _ = Int(msg.command) {
                Text(msg.params.dropFirst().joined(separator: " "))
                    .foregroundStyle(.secondary)
            } else {
                Text(msg.raw)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
