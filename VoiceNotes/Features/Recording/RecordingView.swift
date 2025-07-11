//
//  RecordingView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI

struct RecordingView: View {
    @Environment(AudioRecorder.self) private var audioRecorder: AudioRecorder
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    
    private var buttonTitle: String {
        if audioRecorder.isRecording && !audioRecorder.isPaused { return "Pause" }
        else if audioRecorder.isRecording && audioRecorder.isPaused { return "Resume" }
        else { return "Start" }
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                Text(audioRecorder.recordingDuration.asString())
                    .font(.system(size: 40, design: .monospaced))
                    .padding()
                
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 100)
                    
                    if audioRecorder.isRecording {
                        LiveWaveformView(audioLevels: audioRecorder.audioLevels, color: .red)
                            .frame(height: 100)
                    }
                }
                .cornerRadius(12)
                .padding(.horizontal)
                
                ScrollView {
                    Text(audioRecorder.liveTranscript)
                        .font(.body)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 100)
                
                Spacer()
                
                VStack {
                    if audioRecorder.isRecording {
                        Button("Stop", systemImage: "stop.fill") {
                            isSaving = true
                            audioRecorder.stopRecording()
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.headline)
                        .padding(.bottom, 10)
                    }
                    
                    Button {
                        if !audioRecorder.isRecording {
                            audioRecorder.startRecording()
                        } else if audioRecorder.isPaused {
                            audioRecorder.resumeRecording()
                        } else {
                            audioRecorder.pauseRecording()
                        }
                    } label: {
                        Text(buttonTitle)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(Color.white)
                            .frame(
                                width: audioRecorder.recordingDuration > 0 ? 180 : 80, // Animate from 80 (circle) to 180 (capsule)
                                height: audioRecorder.recordingDuration > 0 ? 60 : 80  // Animate from 80 (circle) to 60 (capsule)
                            )
                            .background {
                                CircleToCapsule(animatableParameter: audioRecorder.recordingDuration > 0 ? 0 : 1)
                                    .fill(Color.red)
                                    .stroke(Color.white, lineWidth: 2)
                            }
                    }
                    .animation(.smooth, value: audioRecorder.isRecording)
                }
                .padding(.bottom, 40)
            }
            .disabled(isSaving)
            
            if isSaving {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView()
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    Text("Saving Recording...")
                        .foregroundStyle(.white)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            audioRecorder.onRecordingFinished = {
                isSaving = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }
        }
        .onDisappear {
            if audioRecorder.isRecording {
                audioRecorder.stopRecording()
            }
        }
        .interactiveDismissDisabled(audioRecorder.isRecording)
    }
}
