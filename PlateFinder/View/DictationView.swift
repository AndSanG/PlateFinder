import SwiftUI

struct DictationView: View {
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var editedPlate = ""
    let onPlateDetected: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            if speechRecognizer.isListening {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Listening...")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if !speechRecognizer.transcribedText.isEmpty {
                        VStack(spacing: 8) {
                            Text("Heard:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(speechRecognizer.transcribedText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(3)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text("Ready to listen")
                        .font(.headline)

                    if !speechRecognizer.transcribedText.isEmpty {
                        let cleaned = cleanPlate(speechRecognizer.transcribedText)
                        Text(cleaned)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .onAppear {
                                onPlateDetected(cleaned)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    dismiss()
                                }
                            }
                    }
                }
            }

            if let error = speechRecognizer.error {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding()
                .background(Color(.systemRed).opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    speechRecognizer.stopListening()
                    speechRecognizer.transcribedText = ""
                    speechRecognizer.error = nil
                    Task {
                        await speechRecognizer.startListening()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Try Again")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding()
        .task {
            await speechRecognizer.startListening()
        }
        .onDisappear {
            speechRecognizer.stopListening()
        }
    }

    private func cleanPlate(_ text: String) -> String {
        text.uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
