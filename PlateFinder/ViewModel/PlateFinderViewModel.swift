//
//  PlateFinderViewModel.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import Foundation
import SwiftSoup

@MainActor
class PlateFinderViewModel: ObservableObject{
    @Published var plateNumber: String = ""
    @Published var car: Car?
    
    @Published var isTesting = true
    
    func getCarInfo() async throws {
        do{
            let scrapper = getScrapper(isTesting: isTesting)
            let html = try await scrapper.getHTMLResponse(with: plateNumber)
            let document = try SwiftSoup.parse(html)
            let table = try document.select("body > table").first()!
            let rows = try table.select("tr")
            let firstRow = try rows[0].select("td")
            let secondRow = try rows[1].select("td")
            let thirdRow = try rows[2].select("td")
            let fourthRow = try rows[3].select("td")
            
            
            car = Car(
                plate: try firstRow[0].text(),
                manufacturer: try firstRow[2].text(),
                colorName: try firstRow[4].text(),
                registrationYear: try firstRow[6].text(),
                model: try secondRow[1].text(),
                segment: try secondRow[3].text(),
                registrationDate: try secondRow[5].text(),
                year: try thirdRow[1].text(),
                service: try thirdRow[3].text(),
                expirationDate: try thirdRow[5].text(),
                tint: try fourthRow[1].text(),
                tintExpirarionDate: try fourthRow[3].text()
            )
        }catch{
            print(error.localizedDescription)
        }
    }
}
