//
//  Recording.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import Foundation
import SwiftData

@Model
final class Recording {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var createdAt: Date
    var duration: TimeInterval
    var title: String
    var transcript: String = ""
    var segmentTimingsData: Data?
    
    var fileURL: URL {
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docPath.appendingPathComponent(fileName)
    }
    
    var segmentTimings: [SegmentTiming] {
        guard let data = segmentTimingsData else { return [] }
        do {
            return try JSONDecoder().decode([SegmentTiming].self, from: data)
        } catch {
            print("Error decoding word timings: \(error)")
            return []
        }
    }
    
    init(id: UUID = UUID(), fileName: String, createdAt: Date, duration: TimeInterval) {
        self.id = id
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        self.title = "Recording \(formatter.string(from: createdAt))"
    }
}

struct SegmentTiming: Codable, Hashable {
    let text: String
    let startTime: TimeInterval
}
