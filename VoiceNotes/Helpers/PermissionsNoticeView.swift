//
//  PermissionsNoticeView.swift
//  VoiceNotes
//
//  Created by Jonathan Rajya on 07/07/2025.
//

import SwiftUI

struct PermissionsNoticeView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Permissions Required")
                .font(.title2)
                .fontWeight(.bold)
            Text("To record audio and provide transcriptions, this app needs access to your microphone and speech recognition.\nPlease grant these permissions in Settings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text("Open Settings")
                    .padding(8)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    PermissionsNoticeView()
}
