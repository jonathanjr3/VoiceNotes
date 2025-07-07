//
//  Item.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
