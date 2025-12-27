//
//  ChannelList.swift
//  mARC
//
//  Created by LN on 27/12/2025.
//

import Foundation

struct ChannelListItem: Identifiable {
    let id = UUID()
    let name: String
    let userCount: Int
    let topic: String
}
