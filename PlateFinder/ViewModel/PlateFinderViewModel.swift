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
    @Published var plateNumber: String = "ABC1234"
    @Published var car: Car?
    
    @Published var isTesting = true
    
    func getCarInfo() async throws {
        do {
            let scrapper = getScrapper(isTesting: isTesting)
            let html = try await scrapper.getHTMLResponse(with: plateNumber)
            let document = try SwiftSoup.parse(html)
            
            // Multiple variable declaration and unwrapping in a single guard let
            guard
                let table = try document.select("body > table").first(),
                let rows = try? table.select("tr"), // Using try? for select("tr") as it returns Elements which is a collection
                rows.count >= 4, // Ensure we have at least 4 rows
                let firstRow = try? rows.get(0).select("td"),
                let secondRow = try? rows.get(1).select("td"),
                let thirdRow = try? rows.get(2).select("td"),
                let fourthRow = try? rows.get(3).select("td")
            else {
                // Determine the specific error for a clearer message
                if try document.select("body > table").first() == nil {
                    throw CarInfoError.tableNotFound
                } else if let retrievedRows = try? document.select("body > table").first()?.select("tr"),
                          retrievedRows.count < 4 {
                    throw CarInfoError.parsingError("Not enough rows found in the table. Expected at least 4, got \(retrievedRows.count).")
                } else {
                    throw CarInfoError.parsingError("Failed to select required table rows or cells.")
                }
            }
            
            // Now, all variables (table, rows, firstRow, secondRow, etc.) are non-optional
            // and you can safely use them below.
            car = Car(
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
                tintExpirarionDate: fourthRow.safeText(at: 3)
            )
            
            
        } catch {
            let errorMessage = "Failed to get car info: \(error.localizedDescription)"
            print(errorMessage)
            throw error
        }
    }
}
