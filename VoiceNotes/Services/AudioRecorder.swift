//
//  AudioRecorder.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI
import AVFoundation
import SwiftData
import Speech
import Accelerate

@Observable final class AudioRecorder {
    var isRecording = false
    var isPaused = false
    var recordingDuration: TimeInterval = 0.0
    var liveTranscript = ""
    var showErrorAlert = false
    var errorMessage = ""
    var audioLevels: [Float] = Array(repeating: 0.0, count: 50)
    
    @ObservationIgnored @AppStorage("audioQuality") private var audioQualitySetting: AudioQuality.RawValue = AudioQuality.medium.rawValue
    
    private var recordingTimer: Timer?
    private var modelContext: ModelContext?
    
    var onRecordingFinished: (() -> Void)?
    
    private let speechRecognizer = SFSpeechRecognizer()!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var tempSegmentTimings: [SegmentTiming] = []
    
    private var audioFile: AVAudioFile?
    private var tempAudioFilename: String?
    
    deinit {
        if isRecording {
            stopAndSaveRecording()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        guard hasSufficientStorage() else {
            showError("Not enough storage space.")
            return
        }
        
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.record, mode: .measurement, options: .allowBluetooth)
            try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showError("Failed to set up audio session: \(error.localizedDescription)")
            return
        }
        
        let inputNode = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            showError("Unable to create recognition request.")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            var isFinal = false
            if let result = result {
                self.liveTranscript = result.bestTranscription.formattedString
                self.tempSegmentTimings = result.bestTranscription.segments.map { SegmentTiming(text: $0.substring, startTime: $0.timestamp) }
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.stopAndSaveRecording()
            }
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.tempAudioFilename = "\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).m4a"
        let audioFileURL = documentPath.appendingPathComponent(self.tempAudioFilename!)
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let selectedQuality = AudioQuality(rawValue: audioQualitySetting) ?? .medium
        var outputSettings = selectedQuality.settings
        outputSettings[AVSampleRateKey] = inputFormat.sampleRate
        outputSettings[AVNumberOfChannelsKey] = inputFormat.channelCount
        
        do {
            self.audioFile = try AVAudioFile(forWriting: audioFileURL, settings: outputSettings)
        } catch {
            showError("Failed to create audio file: \(error.localizedDescription)")
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print("Error writing audio buffer to file: \(error)")
            }
            self.updateAudioLevels(from: buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            
            recordingDuration = 0.0
            isRecording = true
            isPaused = false
            startTimer()
        } catch {
            showError("Could not start audio engine: \(error.localizedDescription)")
        }
    }
    
    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        audioEngine.pause()
        stopTimer()
        isPaused = true
    }
    
    func resumeRecording() {
        guard isRecording, isPaused else { return }
        do {
            try audioEngine.start()
            startTimer()
            isPaused = false
        } catch {
            showError("Failed to resume recording.")
        }
    }
    
    func stopRecording() {
        if isRecording {
            recognitionTask?.finish()
        }
    }
    
    private func stopAndSaveRecording() {
        guard isRecording else { return }
        
        isRecording = false
        isPaused = false
        stopTimer()
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        self.audioFile = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        audioEngine.reset()
        
        guard let context = modelContext, let filename = tempAudioFilename else {
            DispatchQueue.main.async { self.onRecordingFinished?() }
            return
        }
        
        if recordingDuration > 0.5 {
            let newRecording = Recording(fileName: filename, createdAt: Date(), duration: recordingDuration)
            newRecording.transcript = self.liveTranscript
            
            do {
                let data = try JSONEncoder().encode(self.tempSegmentTimings)
                newRecording.segmentTimingsData = data
            } catch {
                print("Failed to encode segment timings: \(error)")
            }
            
            context.insert(newRecording)
            do {
                try context.save()
            } catch {
                print("Failed to save recording metadata: \(error)")
            }
        }
        
        recordingDuration = 0.0
        liveTranscript = ""
        tempSegmentTimings = []
        audioLevels = Array(repeating: 0.0, count: 50)
        
        DispatchQueue.main.async {
            self.onRecordingFinished?()
        }
    }
    
    private func updateAudioLevels(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        
        var rms: Float = 0.0
        vDSP_rmsqv(channelDataValue, vDSP_Stride(buffer.stride), &rms, vDSP_Length(buffer.frameLength))
        
        let normalizedRms = min(max(0, rms * 5), 1)
        
        Task { @MainActor in
            self.audioLevels.removeFirst()
            self.audioLevels.append(normalizedRms)
        }
    }
    
    private func showError(_ message: String) {
        Task { @MainActor in
            self.errorMessage = message
            if self.isRecording { self.stopAndSaveRecording() }
            try? await Task.sleep(nanoseconds: 200_000_000) //0.2 second
            self.showErrorAlert = true
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        if reason == .oldDeviceUnavailable || reason == .override {
            if isRecording {
                self.showError("Audio device changed. Recording stopped and saved.")
            }
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            if isRecording && !isPaused {
                pauseRecording()
            }
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && isPaused {
                    resumeRecording()
                }
            }
        }
    }
    
    private func hasSufficientStorage(thresholdMB: Double = 50.0) -> Bool {
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            do {
                let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
                if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                    return (freeSize.doubleValue / (1024 * 1024)) > thresholdMB
                }
            } catch {
                print("Error getting storage attributes: \(error)")
            }
        }
        return false
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.05
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}
