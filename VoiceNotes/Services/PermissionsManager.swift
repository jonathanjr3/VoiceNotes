//
//  PermissionsManager.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI
import AVFoundation
import Speech

@Observable final class PermissionsManager {
    var micPermission: AVAudioApplication.recordPermission = .undetermined
    var speechPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    var canRecord: Bool {
        micPermission == .granted && speechPermission == .authorized
    }
    
    func requestPermissions() {
        requestMicPermission()
        requestSpeechPermission()
    }
    
    private func requestMicPermission() {
        Task { @MainActor in
            micPermission = await AVAudioApplication.requestRecordPermission() ? .granted : .denied
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechPermission = status
            }
        }
    }
    
    func checkPermissions() {
        micPermission = AVAudioApplication.shared.recordPermission
        speechPermission = SFSpeechRecognizer.authorizationStatus()
    }
}
