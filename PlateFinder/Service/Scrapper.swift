//
//  Scrapper.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 24/06/2025.
//

import Foundation
import SwiftSoup

protocol Scrapping {
    func getHTMLResponse(with plateNumber: String) async throws -> String
}

func getScrapper(isTesting: Bool)->Scrapping{
    var scrapper: Scrapping
    
    if isTesting {
        scrapper = StubScrapper()
    }else{
        scrapper = AntScrapper()
    }
    
    return scrapper
}

struct AntScrapper: Scrapping {
    func getHTMLResponse(with plateNumber: String) async throws -> String {
        guard var urlComponents = URLComponents(string: AppConstants.baseURL) else {
            throw CarInfoError.serverError
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "ps_tipo_identificacion", value: "PLA"),
            URLQueryItem(name: "ps_identificacion", value: plateNumber),
            URLQueryItem(name: "ps_placa", value: "")
        ]
        
        guard let url = urlComponents.url else {
            throw CarInfoError.invalidPlateFormat
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw CarInfoError.serverError
            }
            
            guard let htmlString = String(data: data, encoding: NetworkConfig.defaultEncoding) else {
                throw CarInfoError.parsingError("Unable to decode response")
            }
            
            return htmlString
        } catch {
            if error is CarInfoError {
                throw error
            } else {
                throw CarInfoError.networkError(error)
            }
        }
    }
}

struct StubScrapper: Scrapping {
    func getHTMLResponse(with plateNumber: String) async throws -> String {
        try await Task.sleep(nanoseconds: NetworkConfig.simulatedDelay)
        return try MockDataService.loadMockHTML()
    }
}

// Helper extension for SwiftSoup.Elements to safely get text
extension Elements {
    /// Safely retrieves the text from an element at a given index.
    /// Returns "" if the index is out of bounds or if the element has no text.
    func safeText(at index: Int) -> String {
        guard index < self.count else { return "" }
        do {
            return try self.get(index).text()
        } catch {
            return ""
        }
    }
}
