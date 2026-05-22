//
//  Globals.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 24/06/2025.
//

import Foundation

// MARK: - App Constants
enum AppConstants {
    // MARK: - API Configuration
    static let baseURL = "https://consultaweb.ant.gob.ec/PortalWEB/paginas/clientes/clp_grid_citaciones.jsp"
    static let defaultPlateExample = "ABC1234"
    
    // MARK: - UI Constants
    static let animationDuration: Double = 0.3
    static let cornerRadius: CGFloat = 15
    static let borderWidth: CGFloat = 2
    
    // MARK: - Localization
    static let supportedLanguages = ["en", "es"]
    static let defaultLanguage = "es"

    static func languageDisplayName(for language: String) -> String {
        switch language {
        case "en":
            return "English"
        case "es":
            return "Spanish"
        default:
            return language.uppercased()
        }
    }
    
    static func languageNativeName(for language: String) -> String {
        switch language {
        case "en":
            return "English"
        case "es":
            return "Español"
        default:
            return language.uppercased()
        }
    }
}

// MARK: - Network Configuration
enum NetworkConfig {
    static let defaultEncoding: String.Encoding = .isoLatin1
    static let simulatedDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds
}
