import SwiftUI

struct PlateSearchView: View {
    @Bindable var viewModel: PlateFinderViewModel
    @Binding var selectedTab: ContentView.AppTab
    @State private var showInfoBanner: Bool = true

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let car = viewModel.result {
                VStack {
                    CarDetailView(car: car, viewModel: viewModel)
                    Spacer()
                    returnButton()
                }
            } else if let error = viewModel.error {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(error.localizedDescription)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                    returnButton()
                }
            } else {
                plateInput()
            }
        }
        .navigationTitle("search_title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func returnButton() -> some View {
        Button {
            viewModel.result = nil
            viewModel.error = nil
            viewModel.plateText = ""
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

    private func plateInput() -> some View {
        VStack(spacing: 20) {
            Text("enter_plate".localized)
                .font(.title)

            HStack {
                if let icon = PlateValidator.vehicleIcon(for: viewModel.plateText) {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                        .padding(.leading)
                        .transition(.scale.combined(with: .opacity))
                }

                TextField(AppConstants.defaultPlateExample, text: $viewModel.plateText)
                    .padding(.leading, PlateValidator.vehicleIcon(for: viewModel.plateText) != nil ? 0 : nil)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.plateText) { old, new in
                        if !PlateValidator.isPartiallyValid(new) && !new.isEmpty {
                            viewModel.plateText = old
                        }
                    }
                    .multilineTextAlignment(.center)

                if !viewModel.plateText.isEmpty {
                    Button { viewModel.plateText = "" } label: {
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
                    .stroke(
                        PlateValidator.isComplete(viewModel.plateText) ? Color.blue :
                        (PlateValidator.isPartiallyValid(viewModel.plateText) ? Color.gray : Color.red),
                        lineWidth: 2
                    )
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
                Task { await viewModel.search() }
            } label: {
                Text("consult".localized)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(PlateValidator.isComplete(viewModel.plateText) ? Color.blue : Color.gray)
                    .cornerRadius(AppConstants.cornerRadius)
            }
            .padding(.horizontal)
            .disabled(!PlateValidator.isComplete(viewModel.plateText))
        }
        .padding(.vertical)
        .onReceive(IntentHandler.shared.$plateToSearch) { plate in
            if let plate = plate {
                viewModel.plateText = plate
                Task { await viewModel.search() }
            }
        }
    }
}

#Preview {
    let store = UserDefaultsCarStore(defaults: .init(suiteName: "preview")!)
    let loader = RemoteCarInfoLoader(
        url: URL(string: AppConstants.baseURL)!,
        client: URLSessionHTTPClient(),
        parser: ANTHTMLParser()
    )
    NavigationStack {
        PlateSearchView(
            viewModel: PlateFinderViewModel(loader: loader, store: store, favoritesStore: store),
            selectedTab: .constant(.search)
        )
    }
}
