//
//  ChannelUser.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import Foundation
struct ChannelUser: Identifiable, Hashable {
    let id = UUID()
    var nick: String
    var isOp: Bool = false
    var isVoice: Bool = false
    
    var displayName: String {
        if isOp { return "@\(nick)" }
        if isVoice { return "+\(nick)" }
        return nick
    }
    
    var sortRank: Int {
        if isOp { return 0 }
        if isVoice { return 1 }
        return 2
    }
}
