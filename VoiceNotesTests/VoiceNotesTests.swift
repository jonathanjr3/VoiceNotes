//
//  VoiceNotesTests.swift
//  VoiceNotesTests
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import Testing
@testable import VoiceNotes
import AVFoundation
import Speech

struct VoiceNotesTests {

    @Test func recordingInitialization() {
        let date = Date()
        let duration: TimeInterval = 12.5
        let recording = Recording(fileName: "test.m4a", createdAt: date, duration: duration)

        #expect(recording.fileName == "test.m4a")
        #expect(recording.createdAt == date)
        #expect(recording.duration == duration)
        #expect(recording.transcript.isEmpty)
        #expect(recording.isTranscriptFinal)
        #expect(recording.title.contains("Recording"))
    }

    @Test func timeIntervalFormatting() {
        var interval: TimeInterval = 65
        #expect(interval.asString() == "01:05")
        
        interval = 59
        #expect(interval.asString() == "00:59")
        
        interval = 125
        #expect(interval.asString() == "02:05")
    }

    @Test func audioQualityComputedProperties() {
        let lowQuality = AudioQuality.low
        #expect(lowQuality.description == "32 kbps")
        #expect(lowQuality.fileSizePerMinute == "~0.2 MB/min")
        
        let mediumQuality = AudioQuality.medium
        #expect(mediumQuality.description == "64 kbps")
        #expect(mediumQuality.fileSizePerMinute == "~0.5 MB/min")
        
        let highQuality = AudioQuality.high
        #expect(highQuality.description == "128 kbps")
        #expect(highQuality.fileSizePerMinute == "~1.0 MB/min")
    }
    
    @Test func permissionsManagerCanRecordLogic() {
        let permissionsManager = PermissionsManager()
        
        // Both denied
        permissionsManager.micPermission = .denied
        permissionsManager.speechPermission = .denied
        #expect(permissionsManager.canRecord == false)
        
        // Mic granted, speech denied
        permissionsManager.micPermission = .granted
        permissionsManager.speechPermission = .denied
        #expect(permissionsManager.canRecord == false)

        // Mic denied, speech granted
        permissionsManager.micPermission = .denied
        permissionsManager.speechPermission = .authorized
        #expect(permissionsManager.canRecord == false)
        
        // Both granted
        permissionsManager.micPermission = .granted
        permissionsManager.speechPermission = .authorized
        #expect(permissionsManager.canRecord == true)
        
        // Undetermined
        permissionsManager.micPermission = .undetermined
        permissionsManager.speechPermission = .notDetermined
        #expect(permissionsManager.canRecord == false)
    }

}
