import SwiftUI

/// Inline dictation control that lives inside the plate input field.
/// Tapping toggles listening; each partial transcript is cleaned to
/// plate characters and streamed to the parent while the user speaks.
struct DictationMicButton: View {
    let speechRecognizer: SpeechRecognizer
    let onTranscript: (String) -> Void

    var body: some View {
        Button {
            if speechRecognizer.isListening {
                speechRecognizer.stopListening()
            } else {
                Task { await speechRecognizer.startListening() }
            }
        } label: {
            Image(systemName: speechRecognizer.isListening ? "waveform" : "mic.fill")
                .font(.title3)
                .foregroundStyle(speechRecognizer.isListening ? Color.red : Color.blue)
                .symbolEffect(.variableColor.iterative, isActive: speechRecognizer.isListening)
                .contentTransition(.symbolEffect(.replace))
        }
        .sensoryFeedback(.selection, trigger: speechRecognizer.isListening)
        .accessibilityLabel((speechRecognizer.isListening ? "stop_dictation" : "start_dictation").localized)
        .onChange(of: speechRecognizer.transcribedText) { _, text in
            let cleaned = cleanPlate(text)
            guard !cleaned.isEmpty else { return }
            onTranscript(cleaned)
        }
        .onDisappear { speechRecognizer.stopListening() }
    }

    private func cleanPlate(_ text: String) -> String {
        text.uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}

/// Shown under the plate field when speech recognition fails.
struct DictationErrorLabel: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
    }
}
