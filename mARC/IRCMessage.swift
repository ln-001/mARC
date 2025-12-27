//
//  IRCMessage.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import Foundation

struct IRCMessage: Identifiable{
    let id = UUID()
    let timestamp = Date()
    let raw: String
    
    
    var prefix: String?
    var command: String
    var params: [String] 
    
    
    var nick: String?{
        guard let prefix = prefix else {return nil}
        if let bangIndex = prefix.firstIndex(of: "!"){
            return String(prefix[..<bangIndex])
        }
        return prefix
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
}

func parseIRCMessage(_ raw: String) -> IRCMessage {
    var message = raw
    var prefix: String? = nil
    var params: [String] = []
    
    if message.hasPrefix(":"){
        message.removeFirst()
        if let spaceIndex = message.firstIndex(of: " "){
            prefix = String(message[..<spaceIndex])
            message = String(message[message.index(after: spaceIndex)...])
        }
    }
    var trailing: String? = nil
    if let trailingStart = message.range(of: " :"){
        trailing = String(message[trailingStart.upperBound...])
        message = String(message[..<trailingStart.lowerBound])
    }
    
    let parts = message.split(separator: " ").map(String.init)
    let command = parts.first ?? ""
    params = Array(parts.dropFirst())
    
    
    if let trailing = trailing{
        params.append(trailing)
    }
    
    return IRCMessage(raw: raw, prefix: prefix, command: command, params: params)
}
