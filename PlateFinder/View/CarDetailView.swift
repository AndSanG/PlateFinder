//
//  CarDetailView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 03/07/2025.
//

import SwiftUI

struct CarDetailView: View {
    let car: Car
    var body: some View {
        ScrollView {
            Text(car.manufacturer + " " + car.model)
                .font(.title).bold()
            Text(car.plate)
                .font(.title2)
                .padding(.vertical)
            
            VStack(alignment: .leading){
                CarDetailItem(title: "Año", subtitle: car.year, iconName: "number")
                CarDetailItem(title: "Color", subtitle: car.colorName, iconName: "paintbrush")
                CarDetailItem(title: "Uso", subtitle: String(car.segment.capitalized + " de " + car.service.lowercased()), iconName: "car.2")
                CarDetailItem(title: "Matrícula", subtitle: car.registrationYear, iconName: "document")
                CarDetailItem(title: "Validez de la matrícula", subtitle: String(car.registrationDate + "  ->  " + car.expirationDate), iconName: "calendar.circle")
                if (car.tintExpirarionDate != "" ){
                    CarDetailItem(title: "Validez del polarizado", subtitle: car.tintExpirarionDate, iconName: "calendar")
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
    CarDetailView(car: .mock)
}
