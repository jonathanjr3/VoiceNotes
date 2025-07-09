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
    private var headphonesConnected: Bool = false
    private let playbackSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func prepareAudioPlayback(recording: Recording) {
        self.segmentTimings = recording.segmentTimings
        
        do {
            try playbackSession.setCategory(.playback, mode: .default)
        } catch {
            print("Setting up playback session failed: \(error)")
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Playback failed: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        try? playbackSession.setActive(false)
        isPlaying = false
        stopDisplayLink()
        highlightedSegmentIndex = nil
        playbackLevels = Array(repeating: 0.0, count: 50)
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        try? playbackSession.setActive(false)
        isPlaying = false
        stopDisplayLink()
    }
    
    func resumePlayback() {
        audioPlayer?.play()
        try? playbackSession.setActive(true)
        isPlaying = true
        startDisplayLink()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentPlaybackTime = time
        updateHighlightedSegment()
    }
    
    private func startDisplayLink() {
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
              let _ = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        pausePlayback()
    }
    
    private func normalize(power: Float) -> Float {
        let minDb: Float = -60.0
        let maxDb: Float = 0.0
        let clampedPower = max(minDb, min(power, maxDb))
        let normalized = (clampedPower - minDb) / (maxDb - minDb)
        return pow(normalized, 2)
    }
    
    private func updateHighlightedSegment() {
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
        currentPlaybackTime = 0
        highlightedSegmentIndex = nil
        playbackLevels = Array(repeating: 0.0, count: 50)
    }
}
