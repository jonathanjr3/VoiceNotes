//
//  RecordingActivityAttributes.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 12/07/2025.
//

import Foundation
import ActivityKit

struct RecordingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data that updates the Live Activity
        var recordingDuration: TimeInterval
        var hasFinishedRecording: Bool
    }

    // Static data that doesn't change
    var recordingStartDate: Date
}
