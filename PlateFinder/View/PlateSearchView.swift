import SwiftUI

struct PlateSearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(IntentRouter.self) private var intentRouter
    @State private var plate = ""
    @State private var showInfoBanner = true

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
                        .foregroundColor(.orange)
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
        VStack(spacing: 20) {
            Text("enter_plate".localized)
                .font(.title)

            HStack {
                if let icon = vehicleIcon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                        .padding(.leading)
                        .transition(.scale.combined(with: .opacity))
                }

                TextField(AppConstants.defaultPlateExample, text: $plate)
                    .padding(.leading, vehicleIcon != nil ? 0 : nil)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: plate) { old, new in
                        if !new.isEmpty && PlateValidator.validate(new) == .invalid {
                            plate = old
                        }
                    }
                    .multilineTextAlignment(.center)

                if !plate.isEmpty {
                    Button { plate = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    .padding(.trailing)
                }
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            .cornerRadius(10)
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
            .padding(.horizontal)
            .disabled(!isComplete)
        }
        .padding(.vertical)
    }
}
