//
//  File.swift
//  SwiftScraper
//
//  Created by Andres Sanchez on 24/06/2025.
//

import Foundation

protocol Scrapping {
    func getHTMLResponse(with plateNumber: String) async throws -> String
}

enum CarInfoError: Error, LocalizedError {
    case tableNotFound
    case parsingError(String) 

    var errorDescription: String? {
        switch self {
        case .tableNotFound:
            return "Could not find the car information table on the page."
        case .parsingError(let details):
            return "Failed to parse car information: \(details)"
        }
    }
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

func getURL(with plateNumber: String)->URL{
    URL(string: "https://consultaweb.ant.gob.ec/PortalWEB/paginas/clientes/clp_grid_citaciones.jsp?ps_tipo_identificacion=PLA&ps_identificacion=" + plateNumber + "&ps_placa=")!
}

struct AntScrapper: Scrapping {
    func getHTMLResponse(with plateNumber: String) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: getURL(with: plateNumber))
        let response = String(data: data, encoding: .isoLatin1)!
        return response
    }
}

struct StubScrapper: Scrapping {
    func getHTMLResponse(with plateNumber: String) async throws -> String {
        htmlMock
    }
}
