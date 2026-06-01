import SwiftUI

struct PlateSearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(IntentRouter.self) private var intentRouter
    @State private var plate = ""
    @State private var showInfoBanner = true
    @State private var showDictation = false

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

    private var numberToolbarButtons: some View {
        ForEach(["1","2","3","4","5","6","7","8","9","0"], id: \.self) { digit in
            KeyboardDigitButton(digit: digit, onTap: { plate += digit })
        }
    }

    private var plateInput: some View {
        VStack(spacing: 20) {
            Text("enter_plate".localized)
                .font(.title)

            HStack {
                if let icon = vehicleIcon {
                    Image(systemName: icon)
                        .foregroundStyle(.blue)
                        .font(.title3)
                        .padding(.leading)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }

                TextField(AppConstants.defaultPlateExample, text: $plate)
                    .padding(.leading, vehicleIcon != nil ? 0 : nil)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .onChange(of: plate) { old, new in
                        if !new.isEmpty && PlateValidator.validate(new) == .invalid {
                            plate = old
                        }
                    }
                    .multilineTextAlignment(.center)

                if !plate.isEmpty {
                    Button { plate = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    .accessibilityLabel("clear_text".localized)
                    .padding(.trailing)
                }
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isComplete ? Color.blue : Color.gray, lineWidth: 2)
            )
            .padding(.horizontal)

            Spacer()

            if showInfoBanner {
                InfoBannerView(
                    title: "important".localized,
                    message: "plate_format_info".localized,
                    isShowing: $showInfoBanner
                )
                .frame(height: 100)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.search(plate: plate) }
                } label: {
                    Text("consult".localized)
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isComplete ? Color.blue : Color.gray)
                        .cornerRadius(AppConstants.cornerRadius)
                }
                .disabled(!isComplete)

                Button {
                    showDictation = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 54)
                        .background(Color.blue)
                        .cornerRadius(AppConstants.cornerRadius)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                numberToolbarButtons
            }
        }
        .sheet(isPresented: $showDictation) {
            DictationView { detectedPlate in
                plate = detectedPlate
                showDictation = false
            }
        }
    }
}

private struct KeyboardDigitButton: View {
    let digit: String
    let onTap: () -> Void

    var body: some View {
        Button(digit) { onTap() }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(red: 0.4, green: 0.4, blue: 0.4))
            .clipShape(.rect(cornerRadius: 8))
            .padding(.horizontal, 2)
            .buttonStyle(.plain)
    }
}
