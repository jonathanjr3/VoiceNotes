//
//  PlaybackView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI

struct PlaybackView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var audioPlayer = AudioPlayer()
    @State private var sliderValue: Double = 0
    
    @Bindable var recording: Recording
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 15) {
            Text(recording.createdAt, formatter: dateFormatter)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            LiveWaveformView(audioLevels: audioPlayer.playbackLevels, color: .accentColor)
                .frame(height: 100)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
            
            VStack(alignment: .leading) {
                if recording.transcript.isEmpty {
                    ContentUnavailableView("Couldn't transcribe audio", systemImage: "text.badge.xmark")
                } else {
                    HStack {
                        Label("Transcript", systemImage: "quote.bubble")
                            .font(.footnote)
                        Spacer()
                        Image(systemName: "document.on.document")
                            .onTapGesture {
                                UIPasteboard.general.string = recording.transcript
                            }
                    }
                    Divider()
                    ScrollView {
                        Text(highlightedTranscript())
                            .textSelection(.enabled)
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(12)
            
            Slider(value: $sliderValue, in: 0...audioPlayer.duration, onEditingChanged: { editing in
                if !editing {
                    audioPlayer.seek(to: sliderValue)
                }
            })
            .onChange(of: audioPlayer.currentPlaybackTime) { _, newTime in
                sliderValue = newTime
            }
            
            HStack {
                Text(audioPlayer.currentPlaybackTime.asString())
                Spacer()
                Text(audioPlayer.duration.asString())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            HStack(spacing: 40) {
                Button(action: {
                    let newTime = max(0, audioPlayer.currentPlaybackTime - 15)
                    audioPlayer.seek(to: newTime)
                }) { Image(systemName: "gobackward.15").font(.largeTitle) }
                
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pausePlayback()
                    } else {
                        audioPlayer.resumePlayback()
                    }
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 70))
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                }
                .animation(.bouncy, value: audioPlayer.isPlaying)
                
                Button(action: {
                    let newTime = min(audioPlayer.duration, audioPlayer.currentPlaybackTime + 15)
                    audioPlayer.seek(to: newTime)
                }) { Image(systemName: "goforward.15").font(.largeTitle) }
            }
            .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle($recording.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            audioPlayer.prepareAudioPlayback(recording: recording)
        }
        .onDisappear {
            audioPlayer.stopPlayback()
        }
    }
    
    private func highlightedTranscript() -> AttributedString {
        var attributedString = AttributedString()
        
        for (index, segment) in recording.segmentTimings.enumerated() {
            var segmentString = AttributedString(segment.text + " ")
            if index == audioPlayer.highlightedSegmentIndex {
                segmentString.foregroundColor = Color.accentColor
                segmentString.font = .body.bold()
            }
            attributedString.append(segmentString)
        }
        
        return attributedString
    }
}
