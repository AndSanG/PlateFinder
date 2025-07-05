//
//  CarDetailView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 03/07/2025.
//

import SwiftUI

struct CarDetailView: View {
    let car: Car
    @ObservedObject var viewModel: PlateFinderViewModel
    
    var body: some View {
        ScrollView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(car.manufacturer + " " + car.model)
                        .font(.title).bold()
                    Text(car.plate)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.toggleFavorite(car.plate)
                }) {
                    Image(systemName: viewModel.isFavorite(car.plate) ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(viewModel.isFavorite(car.plate) ? .yellow : .gray)
                }
            }
            .padding(.bottom)
            
            VStack(alignment: .leading){
                CarDetailItem(title: "Año", subtitle: car.year, iconName: "number")
                CarDetailItem(title: "Color", subtitle: car.colorName, iconName: "paintbrush")
                CarDetailItem(title: "Uso", subtitle: String(car.segment.capitalized + " de " + car.service.lowercased()), iconName: "car.2")
                CarDetailItem(title: "Matrícula", subtitle: car.registrationYear, iconName: "document")
                CarDetailItem(title: "Validez de la matrícula", subtitle: String(car.registrationDate + "  ->  " + car.expirationDate), iconName: "calendar.circle")
                if !car.tintExpirationDate.isEmpty {
                    CarDetailItem(title: "Validez del polarizado", subtitle: car.tintExpirationDate, iconName: "calendar")
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
        }
        .padding()
    }
}

#Preview {
    CarDetailView(car: .mock, viewModel: PlateFinderViewModel(userDataService: MockUserDataService()))
}
