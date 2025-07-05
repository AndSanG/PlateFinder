//
//  Car.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 24/06/2025.
//

import Foundation

struct Car: Codable, Identifiable {
    let id = UUID()
    let plate: String
    let manufacturer: String
    let colorName: String
    let registrationYear: String
    let model: String
    let segment: String
    let registrationDate: String
    let year: String
    let service: String
    let expirationDate: String
    let tint: String
    let tintExpirationDate: String // Fixed typo
    
    private enum CodingKeys: String, CodingKey {
        case plate, manufacturer, colorName, registrationYear
        case model, segment, registrationDate, year, service
        case expirationDate, tint, tintExpirationDate
    }
}

extension Car {
    static var mock: Car {
        Car(
            plate: "ABC1234",
            manufacturer: "TOYOTA",
            colorName: "AMARILLO",
            registrationYear: "2025",
            model: "AA COROLLA 1.6",
            segment: "AUTOMOVIL",
            registrationDate: "14-06-2025",
            year: "2009",
            service: "USO PUBLICO",
            expirationDate: "31-05-2030",
            tint: "No existe registro de polarizado",
            tintExpirationDate: ""
        )
    }
}
