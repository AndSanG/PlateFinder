import Foundation
import Speech
import AVFoundation
import Observation

@Observable
@MainActor
final class SpeechRecognizer {
    private(set) var isListening = false
    private(set) var transcribedText = ""
    private(set) var error: String?

    private let speechRecognizer =
        SFSpeechRecognizer(locale: .current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private static let maxListeningDuration: Duration = .seconds(10)
    @ObservationIgnored private var autoStopTask: Task<Void, Never>?

    func startListening() async {
        guard !isListening else { return }
        error = nil

        guard await requestPermissions() else { return }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            error = "speech_unavailable".localized
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "speech_audio_error".localized
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.stopListening()
                        self.finishRecognition()
                    }
                }
                // Errors after a manual/auto stop are cancellation noise — ignore them.
                if error != nil, self.isListening {
                    self.error = "speech_recognition_error".localized
                    self.stopListening()
                    self.finishRecognition()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // outputFormat(forBus:) can report 0 Hz before the session settles;
        // the active session's sampleRate is always valid here.
        guard let format = AVAudioFormat(standardFormatWithSampleRate: session.sampleRate, channels: 1) else {
            self.error = "speech_audio_error".localized
            finishRecognition()
            return
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            transcribedText = ""
            isListening = true
        } catch {
            self.error = "speech_audio_error".localized
            inputNode.removeTap(onBus: 0)
            finishRecognition()
            return
        }

        autoStopTask?.cancel()
        autoStopTask = Task { [weak self] in
            try? await Task.sleep(for: Self.maxListeningDuration)
            guard !Task.isCancelled else { return }
            self?.stopListening()
        }
    }

    func stopListening() {
        autoStopTask?.cancel()
        autoStopTask = nil

        guard isListening else { return }
        isListening = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        // endAudio (not cancel) lets the recognizer deliver its final result.
        recognitionRequest?.endAudio()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func finishRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }

    private func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            error = "speech_permission_denied".localized
            return false
        }

        guard await AVAudioApplication.requestRecordPermission() else {
            error = "mic_permission_denied".localized
            return false
        }
        return true
    }
}
