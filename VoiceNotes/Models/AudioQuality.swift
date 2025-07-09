//
//  AudioQuality.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI
import AVFoundation

enum AudioQuality: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var settings: [String: Any] {
        switch self {
        case .low:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 8000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
            ]
        case .medium:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
        case .high:
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "32 kbps"
        case .medium:
            return "64 kbps"
        case .high:
            return "128 kbps"
        }
    }
    
    var fileSizePerMinute: String {
        let estimatedBitrate: Int
        switch self {
        case .low: estimatedBitrate = 32000
        case .medium: estimatedBitrate = 64000
        case .high: estimatedBitrate = 128000
        }
        let bytesPerMinute = Double(estimatedBitrate) / 8.0 * 60.0
        let megabytesPerMinute = bytesPerMinute / (1024 * 1024)
        return String(format: "~%.1f MB/min", megabytesPerMinute)
    }
}
