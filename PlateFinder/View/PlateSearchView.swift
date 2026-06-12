import SwiftUI

struct PlateSearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(HistoryViewModel.self) private var historyViewModel
    @Environment(AppRouter.self) private var appRouter
    @Environment(IntentRouter.self) private var intentRouter
    @Environment(\.scenePhase) private var scenePhase
    @State private var plate = ""
    @State private var speechRecognizer = SpeechRecognizer()
    @FocusState private var plateFieldIsFocused: Bool

    var body: some View {
        // Every state lives inside the conversation: searches are sent bubbles,
        // results/errors arrive as reply bubbles above the always-present input.
        searchScreen
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
            .onChange(of: viewModel.state) { _, state in
                // Chat-style: a delivered result clears the input; on error the
                // text stays so the user can correct a typo.
                if case .success = state { plate = "" }
            }
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

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }

    private var searchScreen: some View {
        VStack(spacing: 0) {
            // Conversation area — plates read like a chat: the newest sits at
            // the bottom next to the input and older ones scroll up out of view.
            conversationArea

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
                        plateFieldIsFocused = false
                        Task { await viewModel.search(plate: plate) }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(isComplete ? Color.blue : Color(.systemGray3))
                        }
                    }
                    .disabled(!isComplete || isLoading)
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
            .disabled(isLoading)
        }
        // Re-runs after every search-state change so a completed search shows
        // up immediately as the newest bubble in the conversation.
        .task(id: viewModel.state) { await historyViewModel.loadData() }
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

    // MARK: - Conversation area

    private var historyItems: [SearchHistoryItem] {
        if case .loaded(let history, _) = historyViewModel.state { return history }
        return []
    }

    @ViewBuilder
    private var conversationArea: some View {
        if historyItems.isEmpty, case .idle = viewModel.state {
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
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .trailing, spacing: 8) {
                    if !historyItems.isEmpty {
                        // Pinned at the very top, like "load earlier messages"
                        Button {
                            appRouter.isHistoryPresented = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("more_searches".localized)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)

                        // Oldest first so the most recent plate lands at the bottom.
                        // Each item is a chat pair: sent plate + its reply.
                        ForEach(Array(historyItems.reversed()), id: \.plateNumber) { item in
                            VStack(alignment: .trailing, spacing: 8) {
                                plateBubble(item)
                                if let car = item.car {
                                    CarReplyBubble(car: car)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    transientReply
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .animation(.easeInOut(duration: 0.2), value: viewModel.state)
            }
            .defaultScrollAnchor(.bottom)
            .scrollIndicators(.hidden)
        }
    }

    /// Transient tail of the conversation: typing-indicator skeleton while
    /// the server answers, an inline bubble on failure. A success normally
    /// arrives as the newest history pair; the bubble here is only a
    /// fallback for results that never reached the history store.
    @ViewBuilder
    private var transientReply: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            ReplySkeletonBubble()
                .padding(.top, 4)
                .transition(.opacity)
        case .success(let car):
            if historyItems.first?.plateNumber != car.plate {
                CarReplyBubble(car: car)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        case .error(let message):
            errorBubble(message)
                .padding(.top, 4)
                .transition(.opacity)
        }
    }

    private func errorBubble(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.12))
        .clipShape(.rect(cornerRadius: 16))
    }

    /// Sent-message bubble. Tapping re-sends the plate: a fresh server
    /// search, so the pair moves to the bottom with up-to-date data.
    /// (The cached detail stays one tap away on the reply bubble.)
    private func plateBubble(_ item: SearchHistoryItem) -> some View {
        Button {
            plate = item.plateNumber
            plateFieldIsFocused = false
            Task { await viewModel.search(plate: item.plateNumber) }
        } label: {
            Text(item.plateNumber)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.blue)
                .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

}

/// Typing-indicator-style bubble: shimmer placeholders sized like the
/// title reply that will replace it.
private struct ReplySkeletonBubble: View {
    @State private var shimmerOffset: CGFloat = -150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 90, height: 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.35), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
        )
        .clipShape(.rect(cornerRadius: 16))
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 250
            }
        }
        .accessibilityLabel("consulting_ant_database".localized)
    }
}

/// Search result rendered as the "reply" bubble of the conversation:
/// collapsed it shows just the car title; tapping expands the full
/// detail inline, like opening an attachment in a chat.
private struct CarReplyBubble: View {
    let car: Car
    @Environment(HistoryViewModel.self) private var historyViewModel
    @State private var isExpanded = false

    private var isFavorite: Bool {
        if case .loaded(_, let favs) = historyViewModel.state {
            return favs.contains(car.plate)
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(car.manufacturer + " " + car.model + " " + car.year)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(car.plate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Button {
                        Task { await historyViewModel.toggleFavorite(car.plate) }
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(isFavorite ? .yellow : .gray)
                    }
                    .accessibilityLabel(isFavorite ? "remove_from_favorites".localized : "add_to_favorites".localized)
                    .transition(.opacity)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    detailLine("color".localized, car.colorName)
                    detailLine("usage".localized, car.segment.capitalized + " de " + car.service.lowercased())
                    detailLine("registration".localized, car.registrationYear)
                    detailLine("registration_validity".localized, car.registrationDate + " → " + car.expirationDate)
                    if !car.tintExpirationDate.isEmpty {
                        detailLine("tint_validity".localized, car.tintExpirationDate)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    /// One compact rich-text line: secondary label, bold value, wraps
    /// like a chat message instead of using icon rows.
    private func detailLine(_ label: String, _ value: String) -> some View {
        (Text(label + ": ")
            .foregroundStyle(.secondary)
        + Text(value)
            .bold())
            .font(.subheadline)
            .accessibilityLabel("\(label): \(value)")
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
