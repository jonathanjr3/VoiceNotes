//
//  RecordingsListView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI
import SwiftData

struct RecordingsListView: View {
    @Query private var recordings: [Recording]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @State private var selection = Set<UUID>()
    
    private let searchText: String
    
    init(searchText: String) {
        self.searchText = searchText
        
        // Predicate used for search queries
        let predicate = #Predicate<Recording> { recording in
            if searchText.isEmpty {
                return true
            } else {
                return recording.title.localizedStandardContains(searchText) ||
                recording.transcript.localizedStandardContains(searchText)
            }
        }
        
        _recordings = Query(filter: predicate, sort: [SortDescriptor(\.createdAt, order: .reverse)])
    }
    
    var body: some View {
        if recordings.isEmpty {
            if searchText.isEmpty {
                ContentUnavailableView("No Recordings Yet", systemImage: "mic.slash")
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        } else {
            List(recordings, id: \.id, selection: $selection) { recording in
                NavigationLink {
                    PlaybackView(recording: recording)
                } label: {
                    RecordingRowView(recording: recording)
                }
                .swipeActions(allowsFullSwipe: true, content: {
                    Button("Delete", systemImage: "trash.fill", role: .destructive) {
                        delete(recording)
                        saveContext()
                    }
                })
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if editMode?.wrappedValue.isEditing == true {
                        Spacer()
                        Button(role: .destructive) {
                            deleteSelectedRecordings()
                        } label: {
                            Label("Delete \(selection.count)", systemImage: "trash")
                        }
                        .disabled(selection.isEmpty)
                    }
                }
            }
        }
    }
    
    private func deleteSelectedRecordings() {
        do {
            let selectedRecordings = try recordings.filter(#Predicate { selection.contains($0.id) })
            selectedRecordings.forEach { recordingToDelete in
                delete(recordingToDelete)
            }
            saveContext()
            selection.removeAll()
        } catch {
            print("Failed to fetch recordings")
        }
        editMode?.wrappedValue = .inactive
    }
    
    private func delete(_ recording: Recording) {
        do {
            try FileManager.default.removeItem(at: recording.fileURL)
            modelContext.delete(recording)
        } catch {
            print("Failed to delete recording file for \(recording.title): \(error)")
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context after deletion: \(error)")
        }
    }
}

struct RecordingRowView: View {
    let recording: Recording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(recording.title)
                .font(.headline)
            Text(recording.transcript)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack {
                Text(recording.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(recording.duration.asString())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
