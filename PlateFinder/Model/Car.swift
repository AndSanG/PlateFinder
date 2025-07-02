//
//  File.swift
//  SwiftScraper
//
//  Created by Andres Sanchez on 24/06/2025.
//

import Foundation

struct Car {
    //var id = UUID()
    var plate : String
    var manufacturer : String
    var colorName : String
    var registrationYear: String
    var model: String
    var segment : String
    var registrationDate: String
    var year: String
    var service: String
    var expirationDate: String
    var tint: String
    var tintExpirarionDate: String
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
            tintExpirarionDate: ""
        )
    }
}
