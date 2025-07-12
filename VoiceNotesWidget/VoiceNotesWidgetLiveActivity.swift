//
//  VoiceNotesWidgetLiveActivity.swift
//  VoiceNotesWidget
//
//  Created by Jonathan Rajya on 11/07/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct VoiceNotesWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VoiceNotesLiveActivityView(context: context)
                .activityBackgroundTint(Color.black)
                .padding()
                .background(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    VoiceNotesLiveActivityView(context: context)
                        .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "microphone.fill")
                    .foregroundStyle(Color.green)
            } compactTrailing: {
                Image(systemName: "stop.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .white)
            } minimal: {
                Image(systemName: "microphone.fill")
                    .foregroundStyle(Color.green)
            }
        }
    }
}

struct VoiceNotesLiveActivityView: View {
    let context: ActivityViewContext<RecordingActivityAttributes>
    
    var body: some View {
        HStack {
            if context.state.hasFinishedRecording {
                Text(context.state.recordingDuration.asString())
                    .font(.system(.title, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Color.white)
                Spacer()
            } else {
                Text(timerInterval: Date(timeIntervalSinceNow: -context.state.recordingDuration)...Date.distantFuture,
                     pauseTime: context.state.hasFinishedRecording ? Date.now : nil,
                     countsDown: false,
                     showsHours: true)
                .font(.system(.title, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Color.white)
            }
            
            Button(intent: StopRecordingIntent()) {
                Image(systemName: context.state.hasFinishedRecording ? "checkmark.circle" : "stop.circle")
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating)) //TODO: Check why it isn't working
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .white)
                    .font(.largeTitle)
            }
            .buttonStyle(.plain)
        }
    }
}

extension RecordingActivityAttributes {
    fileprivate static var preview: RecordingActivityAttributes {
        RecordingActivityAttributes(recordingStartDate: Date.now)
    }
}

extension RecordingActivityAttributes.ContentState {
    fileprivate static var start: RecordingActivityAttributes.ContentState {
        RecordingActivityAttributes.ContentState(recordingDuration: 0, hasFinishedRecording: false)
    }
    
    fileprivate static var secondsPassed: RecordingActivityAttributes.ContentState {
        RecordingActivityAttributes.ContentState(recordingDuration: 30, hasFinishedRecording: true)
    }
}

#Preview("Notification", as: .content, using: RecordingActivityAttributes.preview) {
    VoiceNotesWidgetLiveActivity()
} contentStates: {
    RecordingActivityAttributes.ContentState.start
    RecordingActivityAttributes.ContentState.secondsPassed
}
