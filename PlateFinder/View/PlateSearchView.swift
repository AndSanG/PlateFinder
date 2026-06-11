import SwiftUI

struct PlateSearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(IntentRouter.self) private var intentRouter
    @Environment(\.scenePhase) private var scenePhase
    @State private var plate = ""
    @State private var speechRecognizer = SpeechRecognizer()
    @FocusState private var plateFieldIsFocused: Bool

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                plateInput
            case .loading:
                LoadingView()
            case .success(let car):
                VStack {
                    CarDetailView(car: car)
                    Spacer()
                    returnButton
                }
            case .error(let message):
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text(message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                    returnButton
                }
            }
        }
        .navigationTitle("search_title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let pending = intentRouter.pendingPlate else { return }
            plate = pending
            await viewModel.search(plate: pending)
            intentRouter.consume()
        }
        .onChange(of: intentRouter.pendingPlate) { _, pending in
            guard let pending else { return }
            plate = pending
            Task { await viewModel.search(plate: pending) }
            intentRouter.consume()
        }
    }

    private var returnButton: some View {
        Button {
            viewModel.reset()
            plate = ""
        } label: {
            Text("return".localized)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 15).stroke(.blue, lineWidth: 1))
        }
        .padding(.horizontal)
    }

    private var plateFormat: PlateFormat { PlateValidator.validate(plate) }

    private var isComplete: Bool {
        plateFormat == .car || plateFormat == .bike || plateFormat == .special
    }

    private var vehicleIcon: String? {
        switch plateFormat {
        case .car:     return "car.fill"
        case .bike:    return "bicycle"
        case .special: return "car.2.fill"
        default:       return nil
        }
    }

    private var plateInput: some View {
        VStack(spacing: 0) {
            // Hero area — fills remaining space above the input card
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.secondary)
                Text("enter_plate".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()

            // Inline error from speech recognition
            if let dictationError = speechRecognizer.error {
                DictationErrorLabel(message: dictationError)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            // Unified input card
            VStack(spacing: 0) {
                // Text field row
                HStack(spacing: 10) {
                    if let icon = vehicleIcon {
                        Image(systemName: icon)
                            .foregroundStyle(.blue)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityHidden(true)
                    }

                    TextField(
                        speechRecognizer.isListening ? "listening".localized : AppConstants.defaultPlateExample,
                        text: $plate
                    )
                    .focused($plateFieldIsFocused)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .onChange(of: plate) { old, new in
                        if !new.isEmpty && PlateValidator.validate(new) == .invalid {
                            plate = old
                        }
                    }

                    if !plate.isEmpty {
                        Button { plate = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("clear_text".localized)
                    }

                    DictationMicButton(speechRecognizer: speechRecognizer) { transcript in
                        plate = transcript
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider()
                    .padding(.horizontal, 12)

                // Action row: format hint on left, submit on right
                HStack {
                    if let icon = vehicleIcon {
                        Image(systemName: icon)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(plate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("plate_format_info".localized)
                            .font(.caption2)
                            .foregroundStyle(Color(.tertiaryLabel))
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        speechRecognizer.stopListening()
                        Task { await viewModel.search(plate: plate) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(isComplete ? Color.blue : Color(.systemGray3))
                    }
                    .disabled(!isComplete)
                    .sensoryFeedback(.impact, trigger: isComplete)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        speechRecognizer.isListening ? Color.red.opacity(0.7) : Color(.systemGray4),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .animation(.default, value: speechRecognizer.isListening)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if plateFieldIsFocused {
                DigitKeyRow { digit in plate += digit }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { plateFieldIsFocused = false }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // Focus requests are dropped until the scene is active and the
            // window is key; .active is the signal that the keyboard can
            // be presented. `initial: true` covers re-appearing while the
            // scene is already active (tab switch, returning from a search).
            guard phase == .active else { return }
            plateFieldIsFocused = true
        }
        .animation(.easeOut(duration: 0.2), value: plateFieldIsFocused)
    }
}

/// Digit row pinned above the keyboard, styled after the system
/// keyboard's number row. Lives in the regular view hierarchy instead
/// of the keyboard toolbar so taps register without bar-item latency.
private struct DigitKeyRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let onTap: (String) -> Void

    private static let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Self.digits, id: \.self) { digit in
                Button {
                    onTap(digit)
                } label: {
                    Text(digit)
                        .font(.system(size: 23))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(keyColor)
                        .clipShape(.rect(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.35), radius: 0, y: 1)
                }
                .buttonStyle(DigitKeyButtonStyle())
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(rowColor)
    }

    private var keyColor: Color {
        colorScheme == .dark ? Color(white: 0.42) : .white
    }

    private var rowColor: Color {
        colorScheme == .dark ? Color(white: 0.16) : Color(red: 0.82, green: 0.84, blue: 0.86)
    }
}

/// Dims the key while pressed, like the system keyboard.
private struct DigitKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.4 : 1)
    }
}
