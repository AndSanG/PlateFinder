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
                VStack{
                    Text("Error \(error.localizedDescription)")
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
            
            TextField("ABC1234", text: $viewModel.plateNumber)
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
