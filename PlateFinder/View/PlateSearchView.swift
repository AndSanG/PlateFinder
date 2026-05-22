//
//  PlateSearchView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import SwiftUI

struct PlateSearchView: View {
    @ObservedObject var viewModel: PlateFinderViewModel
    @Binding var selectedTab: ContentView.AppTab
    @State private var showInfoBanner: Bool = true
    
    private var isValid: Bool {
        PlateValidator.isComplete(viewModel.plateNumber)
    }

    private var isPartiallyValid: Bool {
        PlateValidator.isPartiallyValid(viewModel.plateNumber)
    }

    private var detectedVehicleIcon: String? {
        PlateValidator.vehicleIcon(for: viewModel.plateNumber)
    }
    
    var body: some View {
        Group{
            switch viewModel.stage {
            case .idle:
                plateInput()
            case .loading:
                LoadingView()
            case .loaded(let car):
                VStack{
                    CarDetailView(car: car, viewModel: viewModel)
                    Spacer()
                    returnButton()
                }
            case .error(let error):
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text(error.localizedDescription)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if let suggestion = (error as? CarInfoError)?.recoverySuggestion {
                        Text(suggestion)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    returnButton()
                }
            }
        }
        .navigationTitle("search_title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            Button {
                viewModel.isTesting = !viewModel.isTesting
            } label: {
                Image(systemName: viewModel.isTesting ? "wifi.slash" : "wifi")
                    .foregroundColor(.white)
            }
        }
    }
    
    func returnButton() -> some View{
        Button {
            viewModel.stage = .idle
            viewModel.plateNumber = ""
        } label: {
            Text("return".localized)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.blue, lineWidth: 1)
                )
        }
        .padding(.horizontal)
        
    }
    
    func plateInput() -> some View{
        VStack(spacing: 20) {
            Text("enter_plate".localized)
                .font(.title)
            
            HStack {
                // Show vehicle type icon when valid (on the left)
                if isValid, let icon = detectedVehicleIcon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                        .padding(.leading)
                        .transition(.scale.combined(with: .opacity))
                }
                
                TextField(AppConstants.defaultPlateExample, text: $viewModel.plateNumber)
                    .padding(.leading, isValid && detectedVehicleIcon != nil ? 0 : nil)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.plateNumber) { oldValue, newValue in
                        if(!isPartiallyValid){
                            viewModel.plateNumber = oldValue
                        }
                    }
                    .multilineTextAlignment(.center)
                
                if !viewModel.plateNumber.isEmpty {
                    Button(action: {
                        viewModel.plateNumber = ""
                    }) {
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
                    .stroke(isValid ? Color.blue : (isPartiallyValid ? Color.gray : Color.red), lineWidth: 2)
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
            
            
            Button(action: {
                print("Submit button tapped!")
                print("Plate Number: \(viewModel.plateNumber)")
                Task{
                    await viewModel.getCarInfo()
                }
                
            }) {
                Text("consult".localized)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isValid ? Color.blue : Color.gray)
                    .cornerRadius(AppConstants.cornerRadius)
            }
            .padding(.horizontal)
            .disabled(!isValid)
            
        }
        .padding(.vertical)
        .onReceive(IntentHandler.shared.$plateToSearch) { plate in
            if let plate = plate {
                viewModel.plateNumber = plate
                Task{
                    await viewModel.getCarInfo()
                }
            }
        }
    }
}

struct PlateSearchInput:View {
    var body: some View {
        
    }
}

#Preview {
    PlateSearchView(
        viewModel: PlateFinderViewModel(userDataService: MockUserDataService()),
        selectedTab: .constant(.search)
    )
}
