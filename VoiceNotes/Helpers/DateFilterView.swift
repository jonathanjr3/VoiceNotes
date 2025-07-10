//
//  DateFilterView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI

struct DateFilterView: View {
    @Binding var filterDate: Date?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Filter by Date",
                    selection: $selectedDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        filterDate = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        filterDate = selectedDate
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let date = filterDate {
                    selectedDate = date
                }
            }
        }
    }
}
