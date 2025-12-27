//
//  Channels.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import Foundation
import Combine

class Channel: Identifiable, ObservableObject, Hashable {
    let id = UUID()
    let name: String
    @Published var messages: [IRCMessage] = []
    @Published var users: [ChannelUser] = []
    @Published var topic: String = ""
    @Published var unreadCount: Int = 0

    
    init(name: String) {
        self.name = name
    }
    
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func sortUsers() {
        users.sort { ($0.sortRank, $0.nick.lowercased()) < ($1.sortRank, $1.nick.lowercased()) }
    }
}
