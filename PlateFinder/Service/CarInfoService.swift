//
//  CarInfoService.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 03/07/2025.
//

import Foundation
import SwiftSoup

struct CarInfoService{
    
    func getCarInfo(with plateNumber: String, isTesting: Bool) async throws -> Car{
        do {
            let scrapper = getScrapper(isTesting: isTesting)
            let html = try await scrapper.getHTMLResponse(with: plateNumber)
            let document = try SwiftSoup.parse(html)
            let car = try parseCarInfo(from: document)
            return car
        } catch {
            throw error
        }
    }
    
    func parseCarInfo(from document: Document) throws -> Car {
        guard let table = try document.select("body > table").first() else {
            throw CarInfoError.noDataFound
        }
        
        let rows = try table.select("tr")
        guard rows.count >= 4 else {
            throw CarInfoError.noDataFound
        }
        
        let firstRow = try rows.get(0).select("td")
        let secondRow = try rows.get(1).select("td")
        let thirdRow = try rows.get(2).select("td")
        let fourthRow = try rows.get(3).select("td")
        
        return Car(
            plate: firstRow.safeText(at: 0),
            manufacturer: firstRow.safeText(at: 2),
            colorName: firstRow.safeText(at: 4),
            registrationYear: firstRow.safeText(at: 6),
            model: secondRow.safeText(at: 1),
            segment: secondRow.safeText(at: 3),
            registrationDate: secondRow.safeText(at: 5),
            year: thirdRow.safeText(at: 1),
            service: thirdRow.safeText(at: 3),
            expirationDate: thirdRow.safeText(at: 5),
            tint: fourthRow.safeText(at: 1),
            tintExpirationDate: fourthRow.safeText(at: 3)
        )
    }
}




