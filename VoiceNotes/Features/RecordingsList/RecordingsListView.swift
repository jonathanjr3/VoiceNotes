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
    private var filterDate: Date?
    
    init(searchText: String, filterDate: Date?) {
        self.searchText = searchText
        self.filterDate = filterDate
        
        let predicate: Predicate<Recording>?
        
        if let filterDate {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: filterDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            if !searchText.isEmpty {
                predicate = #Predicate<Recording> { recording in
                    (recording.createdAt >= startOfDay && recording.createdAt < endOfDay) &&
                    (recording.title.localizedStandardContains(searchText) ||
                     recording.transcript.localizedStandardContains(searchText))
                }
            } else {
                predicate = #Predicate<Recording> { recording in
                    recording.createdAt >= startOfDay && recording.createdAt < endOfDay
                }
            }
        } else if !searchText.isEmpty {
            predicate = #Predicate<Recording> { recording in
                recording.title.localizedStandardContains(searchText) ||
                recording.transcript.localizedStandardContains(searchText)
            }
        } else {
            predicate = nil
        }
        
        _recordings = Query(filter: predicate, sort: [SortDescriptor(\.createdAt, order: .reverse)])
    }
    
    private var groupedRecordings: [Date: [Recording]] {
        guard !recordings.isEmpty else { return [:] }
        return Dictionary(grouping: recordings) { recording in
            Calendar.current.startOfDay(for: recording.createdAt)
        }
    }
    
    private var sortedDates: [Date] {
        groupedRecordings.keys.sorted(by: >)
    }
    
    var body: some View {
        if recordings.isEmpty {
            if filterDate == nil && searchText.isEmpty {
                ContentUnavailableView("No Recordings Yet", systemImage: "mic.slash")
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        } else {
            List(selection: $selection) {
                ForEach(sortedDates, id: \.self) { date in
                    Section(header: Text(sectionHeaderTitle(for: date))) {
                        if let recordingsForDate = groupedRecordings[date] {
                            ForEach(recordingsForDate) { recording in
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
                        }
                    }
                }
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
    
    private func sectionHeaderTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(date: .long, time: .omitted)
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
            Text(recording.isTranscriptFinal ? recording.transcript : "Transcribing audio...")
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
