//
//  VoiceNotesApp.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI
import SwiftData

@main
struct VoiceNotesApp: App {
    @State private var audioRecorder = AudioRecorder()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recording.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            VoiceNotesView()
                .environment(audioRecorder)
                .onReceive(NotificationCenter.default.publisher(for: UIScene.didDisconnectNotification)) { _ in
                    audioRecorder.stopAndSaveRecording(isTerminating: true)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
