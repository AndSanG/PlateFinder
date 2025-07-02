//
//  PlateSearchView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import SwiftUI

struct PlateSearchView: View {
    @StateObject var viewModel = PlateFinderViewModel()
    
    private let validationRegex = "^[A-Z]{3}\\d{4}$"
    private var isValid: Bool {
        let regex = "^[a-zA-Z]{3}[0-9]{4}$"
        return viewModel.plateNumber.range(of: regex, options: .regularExpression) != nil
    }
    private var isPartiallyValid: Bool {
        let regex = "^[a-zA-Z]{0,3}[0-9]{0,4}$"
        return viewModel.plateNumber.range(of: regex, options: .regularExpression) != nil
    }
    
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ingrese la placa")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(viewModel.isTesting ? Color.orange : Color.blue)
                .onTapGesture {
                    viewModel.isTesting = !viewModel.isTesting
                }
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
                .onChange(of: viewModel.plateNumber) { newValue in
                    var validatedText = ""
                    var lettersCount = 0
                    var numbersCount = 0
                    
                    for char in newValue {
                        if lettersCount < 3 && char.isLetter {
                            validatedText.append(char.uppercased())
                            lettersCount += 1
                        } else if lettersCount == 3 && numbersCount < 4 && char.isNumber {
                            validatedText.append(char)
                            numbersCount += 1
                        } else {
                            break
                        }
                    }
                    
                    if newValue.count > 7 {
                        viewModel.plateNumber = String(newValue.prefix(7))
                    }
                    
                    if validatedText != self.viewModel.plateNumber {
                        viewModel.plateNumber = validatedText
                    }
                }
                .padding(.horizontal)
            
            Button(action: {
                print("Submit button tapped!")
                print("Plate Number: \(viewModel.plateNumber)")
                Task{
                    do{
                        try await viewModel.getCarInfo()
                    }
                    catch{
                        print(error.localizedDescription)
                    }
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
            
            if let car = viewModel.car {
                Text(car.model)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    /// Provides a user-friendly message based on the validation status.
    private var validationMessage: String {
        if viewModel.plateNumber.isEmpty {
            return "Please enter a 3-letter, 4-number code."
        } else if isValid {
            return "Input is valid!"
        } else {
            return "Invalid format. E.g., ABC1234"
        }
    }
}

#Preview {
    PlateSearchView()
}
