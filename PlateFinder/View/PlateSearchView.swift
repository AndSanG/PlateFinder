import SwiftUI

struct PlateSearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(HistoryViewModel.self) private var historyViewModel
    @Environment(AppRouter.self) private var appRouter
    @Environment(IntentRouter.self) private var intentRouter
    @Environment(\.scenePhase) private var scenePhase
    @State private var plate = ""
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var scrollPosition = ScrollPosition(edge: .bottom)
    @State private var showClearChatAlert = false
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
            .alert("clear_chat".localized, isPresented: $showClearChatAlert) {
                Button("clear".localized, role: .destructive) {
                    viewModel.reset()
                    // Land on a calm clean slate: no keyboard covering it
                    plateFieldIsFocused = false
                    Task { await historyViewModel.clearChat() }
                }
                Button("cancel".localized, role: .cancel) { }
            } message: {
                Text("clear_chat_confirmation".localized)
            }
            .onChange(of: viewModel.state) { _, state in
                // Chat-style: a delivered result clears the input; on error the
                // text stays so the user can correct a typo.
                if case .success = state { plate = "" }
                // Reveal the newest bubbles even if the user had scrolled up
                // (e.g. to reach the "more searches" link). Once at the bottom,
                // the anchor keeps tracking the content that arrives next.
                withAnimation(.easeInOut(duration: 0.2)) {
                    scrollPosition.scrollTo(edge: .bottom)
                }
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
            // Keyboard dismissal is a simultaneous gesture scoped to this area:
            // it never steals taps from bubble buttons (collapse/favorite) and
            // never fires on the input card, where it would fight the field's
            // own focus.
            conversationArea
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded { plateFieldIsFocused = false })
                // History entry point floats over the chat, always reachable
                // regardless of scroll position or conversation state.
                .overlay(alignment: .topTrailing) {
                    Button {
                        appRouter.isHistoryPresented = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                    .accessibilityLabel("more_searches".localized)
                }
                // Clear-chat floats centered at the top, always visible while
                // there are bubbles to clear.
                .overlay(alignment: .top) {
                    if !historyItems.isEmpty {
                        Button {
                            showClearChatAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "eraser")
                                    .font(.caption2)
                                    .accessibilityHidden(true)
                                Text("clear_chat".localized)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        }
                        .padding(.top, 8)
                    }
                }

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

    /// Everything the store knows, regardless of the soft-clear cutoff.
    private var storedHistory: [SearchHistoryItem] {
        if case .loaded(let history, _) = historyViewModel.state { return history }
        return []
    }

    /// What the conversation shows: only searches newer than the cutoff.
    private var historyItems: [SearchHistoryItem] {
        guard let cutoff = historyViewModel.chatCutoff else { return storedHistory }
        return storedHistory.filter { $0.searchDate > cutoff }
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
            // Fill both axes so overlays anchored to this area (history
            // button, clear pill) align with the real screen edges.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                // Plain VStack on purpose: LazyVStack only estimates content
                // height, and combined with defaultScrollAnchor(.bottom) the
                // viewport can anchor against a stale height when history
                // loads async, leaving the chat blank. History caps at 50
                // items, so eager layout is cheap.
                VStack(alignment: .trailing, spacing: 8) {
                    if !historyItems.isEmpty {
                        // Last 5 pairs only — the full story lives behind the
                        // "more searches" sheet. Oldest first so the most
                        // recent plate lands at the bottom next to the input.
                        ForEach(Array(historyItems.prefix(5).reversed()), id: \.plateNumber) { item in
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
                .padding(.bottom, 28)
                .animation(.easeInOut(duration: 0.2), value: viewModel.state)
            }
            .defaultScrollAnchor(.bottom)
            .scrollPosition($scrollPosition)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
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
        // The whole bubble is the expand/collapse button — any tap on it
        // (title or detail) toggles, like opening a chat attachment. The
        // star overlay sits on top and keeps its own hit area.
        Button {
            // Explicit transaction so the bubble, its overlays (star badge,
            // chevron) and the scroll re-anchor all animate together; an
            // implicit .animation(value:) would only cover this subtree.
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(car.manufacturer + " " + car.model + " " + car.year)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(car.plate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                // Room for the chevron pinned at the bubble's corner
                .padding(.trailing, 20)

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
        }
        .buttonStyle(.plain)
        // Chevron stays pinned to the bubble's upper-right corner in both states
        .overlay(alignment: .topTrailing) {
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .padding(10)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        // Favorite star as a reaction badge on the bottom edge, 16px in from
        // the left border. It dips at most ~9pt into the bubble — less than
        // the 10pt vertical padding — so it can never cover the text.
        .overlay(alignment: .bottomLeading) {
            Button {
                Task { await historyViewModel.toggleFavorite(car.plate) }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(isFavorite ? .yellow : .gray)
                    .padding(5)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
            .offset(x: 16, y: 12)
            .accessibilityLabel(isFavorite ? "remove_from_favorites".localized : "add_to_favorites".localized)
        }
        // Hugging content caps its wrapping at 75% of the conversation width
        .containerRelativeFrame(.horizontal, alignment: .leading) { length, _ in
            length * 0.75
        }
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
