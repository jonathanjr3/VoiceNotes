//
//  StartRecordingIntent.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 12/07/2025.
//

import Foundation
import AppIntents

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stops the current audio recording.")

    func perform() async throws -> some IntentResult {
        await AudioRecorder.shared.stopRecording()
        return .result()
    }
}
