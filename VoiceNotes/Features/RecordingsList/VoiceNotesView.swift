//
//  VoiceNotesView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI

struct VoiceNotesView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var audioRecorder = AudioRecorder()
    @State private var permissionsManager = PermissionsManager()
    
    @State private var searchText = ""
    @State private var isShowingRecordingView = false
    @State private var isShowingSettingsView = false
    @State private var editMode: EditMode = .inactive
    @State private var isShowingDateFilter = false
    @State private var filterDate: Date?
    
    var body: some View {
        NavigationStack {
            VStack {
                if !permissionsManager.canRecord {
                    PermissionsNoticeView()
                } else {
                    RecordingsListView(searchText: searchText, filterDate: filterDate)
                        .environment(\.editMode, $editMode)
                }
                
                Spacer()
                
                if !editMode.isEditing {
                    Button(action: {
                        isShowingRecordingView = true
                    }) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(permissionsManager.canRecord ? .red : .gray)
                    }
                    .disabled(!permissionsManager.canRecord)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom)
                }
            }
            .navigationTitle("Voice Notes")
            .searchable(text: $searchText, prompt: "Search Title and Transcripts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(editMode.isEditing ? "Done" : "Edit") {
                        withAnimation {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        isShowingDateFilter = true
                    }
                    Button("Settings", systemImage: "gear") {
                        isShowingSettingsView = true
                    }
                }
            }
            .onAppear {
                audioRecorder.setup(modelContext: modelContext)
                permissionsManager.checkPermissions()
                if permissionsManager.micPermission == .undetermined || permissionsManager.speechPermission == .notDetermined {
                    permissionsManager.requestPermissions()
                }
            }
            .sheet(isPresented: $isShowingRecordingView) {
                RecordingView(audioRecorder: audioRecorder)
            }
            .sheet(isPresented: $isShowingSettingsView) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingDateFilter) {
                DateFilterView(filterDate: $filterDate)
                    .presentationDetents([.medium])
            }
            .alert("Error", isPresented: $audioRecorder.showErrorAlert, actions: {
                Button("OK") {
                    audioRecorder.showErrorAlert = false
                }
            }, message: {
                Text(audioRecorder.errorMessage)
            })
        }
    }
}
