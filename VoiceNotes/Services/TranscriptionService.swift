//
//  TranscriptionService.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 11/07/2025.
//

import Foundation
import SwiftData
import Speech

@Observable
class TranscriptionService {
    private let speechRecognizer = SFSpeechRecognizer()!

    func processPendingRecordings(modelContext: ModelContext) {
        let predicate = #Predicate<Recording> { !$0.isTranscriptFinal }
        let fetchDescriptor = FetchDescriptor(predicate: predicate)
        
        guard let recordingsToProcess = try? modelContext.fetch(fetchDescriptor), !recordingsToProcess.isEmpty else {
            return
        }

        for recording in recordingsToProcess {
            reTranscribe(recording: recording, modelContext: modelContext)
        }
    }

    private func reTranscribe(recording: Recording, modelContext: ModelContext) {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else { return }

        let audioURL = recording.fileURL

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        speechRecognizer.recognitionTask(with: request) { result, error in
            if let result = result, result.isFinal {
                recording.transcript = result.bestTranscription.formattedString
                let segmentTimings = result.bestTranscription.segments.map {
                    SegmentTiming(text: $0.substring, startTime: $0.timestamp)
                }
                
                do {
                    let data = try JSONEncoder().encode(segmentTimings)
                    recording.segmentTimingsData = data
                    recording.isTranscriptFinal = true
                    try modelContext.save()
                } catch {
                    print("Failed to save final transcript: \(error)")
                }
            } else if let error = error {
                print("Re-transcription failed: \(error)")
            }
        }
    }
}
