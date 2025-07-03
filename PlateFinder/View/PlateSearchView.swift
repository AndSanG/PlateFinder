//
//  PlateSearchView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import SwiftUI

struct PlateSearchView: View {
    @StateObject var viewModel = PlateFinderViewModel()
    private let fullValidationRegex = "^[A-Z]{3}\\d{4}$"
    private let partialValidationRegex = "^[A-Z]{0,3}\\d{0,4}$"
    private var isValid: Bool {
        return viewModel.plateNumber.range(of: fullValidationRegex, options: .regularExpression) != nil
    }
    private var isPartiallyValid: Bool {
        return viewModel.plateNumber.range(of: partialValidationRegex, options: .regularExpression) != nil
    }
    
    var body: some View {
        
        Group{
            Text("Ingrese la placa")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(viewModel.isTesting ? Color.orange : Color.blue)
                .onTapGesture {
                    viewModel.isTesting = !viewModel.isTesting
                }
            
            switch viewModel.state {
            case .idle:
                plateInput()
                Spacer()
            case .loading:
                ProgressView()
            case .loaded(let car):
                Text(car.plate + "\n" + car.model + "\n" + car.year + "\n" + car.tint)
                Spacer()
                returnButton()
            case .error(let error):
                Text("Error \(error.localizedDescription)")
                Spacer()
                returnButton()
            }
        }
    }
    
    func returnButton() -> some View{
        Button {
            viewModel.state = .idle
        } label: {
            Text("Regresar")
        }
    }
    
    func plateInput() -> some View{
        VStack(spacing: 20) {
            
            TextField("ABC1234", text: $viewModel.plateNumber)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isValid ? Color.green : (isPartiallyValid ? Color.gray : Color.red), lineWidth: 2)
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
            
            Button(action: {
                print("Submit button tapped!")
                print("Plate Number: \(viewModel.plateNumber)")
                Task{
                    await viewModel.getCarInfo()
                }

            }) {
                Text("Submit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isValid ? Color.blue : Color.gray)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            .disabled(!isValid)
            
        }
        .padding(.vertical)
    }
}

struct PlateSearchInput:View {
    var body: some View {
        
    }
}

#Preview {
    PlateSearchView()
}
