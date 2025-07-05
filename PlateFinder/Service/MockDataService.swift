//
//  MockDataService.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import Foundation

/// Service responsible for loading mock data from external files
struct MockDataService {
    
    /// Loads mock HTML with proper encoding (as used by the real service)
    /// - Returns: HTML string with ISO Latin 1 encoding like the real response
    static func loadMockHTML() throws -> String {
        guard let url = Bundle.main.url(forResource: "mock_response", withExtension: "html") else {
            throw CarInfoError.parsingError("Mock HTML file not found in bundle")
        }
        
        do {
            let data = try Data(contentsOf: url)
            // Use the same encoding as the real service for consistency
            guard let htmlContent = String(data: data, encoding: NetworkConfig.defaultEncoding) else {
                throw CarInfoError.parsingError("Failed to decode mock HTML with ISO Latin 1 encoding")
            }
            return htmlContent
        } catch {
            throw CarInfoError.parsingError("Failed to load mock HTML file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Constants for Mock Data
extension AppConstants {
    /// File name constants for mock data
    enum MockData {
        static let htmlFileName = "mock_response"
        static let htmlFileExtension = "html"
    }
}
