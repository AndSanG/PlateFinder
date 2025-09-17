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
            .padding(16) 
            
            VStack(alignment: .leading){
                CarDetailItem(title: "year".localized, subtitle: car.year, iconName: "number")
                CarDetailItem(title: "color".localized, subtitle: car.colorName, iconName: "paintbrush")
                CarDetailItem(title: "usage".localized, subtitle: String(car.segment.capitalized + " de " + car.service.lowercased()), iconName: "car.2")
                CarDetailItem(title: "registration".localized, subtitle: car.registrationYear, iconName: "document")
                CarDetailItem(title: "registration_validity".localized, subtitle: String(car.registrationDate + "  ->  " + car.expirationDate), iconName: "calendar.circle")
                if !car.tintExpirationDate.isEmpty {
                    CarDetailItem(title: "tint_validity".localized, subtitle: car.tintExpirationDate, iconName: "calendar")
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )

        }
    }
}

#Preview {
    CarDetailView(
        car: Car.mock,
        viewModel: PlateFinderViewModel(userDataService: MockUserDataService())
    )
}
