//
//  AudioPlayer.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI
import AVFoundation

@Observable final class AudioPlayer: NSObject {
    var isPlaying = false
    var currentPlaybackTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackLevels: [Float] = Array(repeating: 0.0, count: 50)
    var highlightedSegmentIndex: Int? = nil
    
    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private var segmentTimings: [SegmentTiming] = []
    private let playbackSession = AVAudioSession.sharedInstance()
    
    func prepareAudioPlayback(recording: Recording) {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        
        self.segmentTimings = recording.segmentTimings
        
        do {
            try playbackSession.setCategory(.playback, mode: .default, options: [.duckOthers])
        } catch {
            print("Setting up playback session failed: \(error)")
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL, fileTypeHint: AVFileType.m4a.rawValue)
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Playback failed: \(error)")
        }
    }
    
    func stopPlayback() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        
        audioPlayer?.stop()
        try? playbackSession.setActive(false)
        isPlaying = false
        stopDisplayLink()
        highlightedSegmentIndex = nil
        playbackLevels = Array(repeating: 0.0, count: 50)
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        stopDisplayLink()
    }
    
    func resumePlayback() {
        try? playbackSession.setActive(true, options: .notifyOthersOnDeactivation)
        audioPlayer?.play()
        isPlaying = true
        startDisplayLink()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentPlaybackTime = time
        updateHighlightedSegment()
    }
    
    private func startDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackTime))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updatePlaybackTime() {
        guard let player = audioPlayer else { return }
        currentPlaybackTime = player.currentTime
        updateHighlightedSegment()
        
        player.updateMeters()
        let power = player.averagePower(forChannel: 0)
        let normalizedPower = normalize(power: power)
        
        self.playbackLevels.removeFirst()
        self.playbackLevels.append(normalizedPower)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        // If the old device (e.g., headphones) is unavailable, pause playback.
        if reason == .oldDeviceUnavailable && isPlaying {
            pausePlayback()
        }
    }
    
    private func normalize(power: Float) -> Float {
        let minDb: Float = -60.0
        let maxDb: Float = 0.0
        let clampedPower = max(minDb, min(power, maxDb))
        let normalized = (clampedPower - minDb) / (maxDb - minDb)
        return normalized
    }
    
    private func updateHighlightedSegment() {
        // Find the index of the last segment whose start time is before or at the current time
        let index = segmentTimings.lastIndex { $0.startTime <= currentPlaybackTime }
        if highlightedSegmentIndex != index {
            highlightedSegmentIndex = index
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopDisplayLink()
    }
}
