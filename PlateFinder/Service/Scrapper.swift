//
//  File.swift
//  SwiftScraper
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
        let endPoint = URL(string: "https://consultaweb.ant.gob.ec/PortalWEB/paginas/clientes/clp_grid_citaciones.jsp?ps_tipo_identificacion=PLA&ps_identificacion=" + plateNumber + "&ps_placa=")!
        let (data, _) = try await URLSession.shared.data(from: endPoint)
        let response = String(data: data, encoding: .isoLatin1)!
        return response
    }
}

struct StubScrapper: Scrapping {
    func getHTMLResponse(with plateNumber: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        return htmlMock
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
