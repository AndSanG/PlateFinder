//
//  PlateSearchView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import SwiftUI

struct PlateSearchView: View {
    @StateObject var viewModel = PlateFinderViewModel()
    @State private var showInfoBanner: Bool = true
    
    private let fullValidationRegex = AppConstants.fullPlateValidationRegex
    private let partialValidationRegex = AppConstants.partialPlateValidationRegex
    private var isValid: Bool {
        return viewModel.plateNumber.range(of: fullValidationRegex, options: .regularExpression) != nil
    }
    private var isPartiallyValid: Bool {
        return viewModel.plateNumber.range(of: partialValidationRegex, options: .regularExpression) != nil
    }
    
    var body: some View {
        Group{
            switch viewModel.stage {
            case .idle:
                plateInput()
            case .loading:
                ProgressView()
            case .loaded(let car):
                VStack{
                    CarDetailView(car: car)
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
        .navigationTitle("Busqueda")
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
        } label: {
            Text("Regresar")
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
            Text("Ingrese la placa")
                .font(.title)
            
            TextField(AppConstants.defaultPlateExample, text: $viewModel.plateNumber)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isValid ? Color.blue : (isPartiallyValid ? Color.gray : Color.red), lineWidth: 2)
                )
                .keyboardType(.asciiCapable)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .onChange(of: viewModel.plateNumber) { oldValue, newValue in
                    if(!isPartiallyValid){
                        viewModel.plateNumber = oldValue
                    }
                }
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            Spacer()
            
            if showInfoBanner {
                InfoBannerView(
                    title: "Importante",
                    message: "Ingrese la placa sin usar guion",
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
                Text("Consultar")
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
    PlateSearchView()
}
