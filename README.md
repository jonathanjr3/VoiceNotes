# Voice Notes

## Project Overview

Voice Notes is a native iOS audio recording app. The app records audio, provides real-time audio visualization and transcription, and saves the recordings for later playback.

## Features

* **Audio Recording**: Using `AVAudioEngine`.
* **Audio Session Management**: The app correctly configures the audio session for recording and handles interruptions and route changes.
* **Real-time Audio Monitoring**: Visual feedback of audio levels during both recording and playback.
* **Transcription**: On-device transcription of recordings using `SFSpeechRecognizer`.
* **Data Persistence**: Recordings and their metadata are saved using SwiftData. Audio files are encrypted.
* **User Interface**: Built with SwiftUI. It includes a list of recordings grouped by date, a search functionality which searches across recording title and transcriptions, a date filter option and a playback view.
* **Configurable Quality**: Select from low, medium, or high audio quality settings.
* **Live Activity**: Shows a live activity with duration of recording and a stop button to stop recording.

## Architecture and Design

### Audio System

The core of the audio recording system is built around `AVAudioEngine`. This provides control over the audio processing graph, allowing for features like real-time audio level monitoring. The `AudioRecorder` class encapsulates all the recording logic, including:

* **Session Management**: Setting up the `AVAudioSession` with the appropriate category and options for recording.
* **Interruption**: The app subscribes to `AVAudioSession.interruptionNotification` to listen for any interruptions to audio. Recording pauses during interruptions like phone calls and resumes automatically if `AVAudioSession.InterruptionOptions` contains `shouldResume` as it's generally safe to resume recording if the system returns this value.
* **Route Change Handling**: The app subscribes to `AVAudioSession.routeChangeNotification` to listen for audio route change notifications. Recording stops if the reason is anything other than `categoryChange` as this reason is triggered whenever `AVAudioSession.sharedInstance().setCategory` is called. Any other reason will cause a crash because the audio bitrate won't usually match between devices (phone's mic and bluetooth mic for example) and that's why the recording is stopped.
* **File Management**: Audio is recorded to a temporary file, which is then saved to the app's document directory with encryption upon completion.

### Data Persistence

The application uses SwiftData to manage all its data:

* **Recording**: This model stores the metadata for each recording, including the file name, creation date, duration, title, and the transcript. The `fileURL` is a computed property that points to the location of the audio file on disk.
* **Encryption**: Audio files are encrypted using `URLFileProtection.completeUnlessOpen` option.

### User Interface

The UI is built entirely with SwiftUI:

* **Main View**: The `VoiceNotesView` is the main entry point, containing the list of recordings and the primary record button.
* **Recording View**: A dedicated `RecordingView` is presented modally for new recordings, showing the recording time, a live waveform, and the live transcript.
* **Playback View**: The `PlaybackView` allows users to listen to their recordings, view the transcript, and see a waveform of the audio.

## How to Set Up

1.  Clone the repository.
2.  Open the `VoiceNotes.xcodeproj` file in Xcode.
3.  Select a development team and change the bundle identifier to a unique string.
4.  Build and run the app on a physical iOS device to test audio recording functionality.

## Known Issues and Limitations

* **Backend Transcription**: The app currently only uses on-device transcription. It does not segment audio and send it to a backend service like OpenAI Whisper.

## Future Work

* **Backend Integration**: Implement audio segmentation and integration with a backend transcription service.
* **Accessibility**: Enhance the app's accessibility with full VoiceOver support and improved accessibility labels.