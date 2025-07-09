//
//  SettingsView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("audioQuality") private var audioQuality: AudioQuality.RawValue = AudioQuality.medium.rawValue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Quality", selection: $audioQuality) {
                        ForEach(AudioQuality.allCases) { quality in
                            Text(quality.rawValue).tag(quality.rawValue)
                        }
                    }
                } header: {
                    Label("Audio Quality", systemImage: "waveform")
                } footer: {
                    if let quality = AudioQuality(rawValue: audioQuality) {
                        Text("\(quality.description), \(quality.fileSizePerMinute)")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            })
        }
        .presentationDetents([.medium, .large])
    }
}
