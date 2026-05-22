//
//  LanguageManager.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 09/07/2025.
//

import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selected_language")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            updateBundle()
        }
    }
    
    private var bundle: Bundle
    
    private init() {
        // Try to get the saved language
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") {
            self.currentLanguage = savedLanguage
        } else {
            // Use the user's preferred language if supported, otherwise fallback
            let preferred = Locale.preferredLanguages.compactMap { lang in
                let code = lang.components(separatedBy: "-").first ?? lang
                return AppConstants.supportedLanguages.contains(code) ? code : nil
            }.first
            self.currentLanguage = preferred ?? AppConstants.defaultLanguage
        }
        self.bundle = Bundle.main
        updateBundle()
    }
    
    func setLanguage(_ language: String) {
        guard AppConstants.supportedLanguages.contains(language) else { return }
        currentLanguage = language
    }
    
    var currentLocale: Locale {
        return Locale(identifier: currentLanguage)
    }
    
    private func updateBundle() {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to main bundle if language bundle not found
            self.bundle = Bundle.main
            return
        }
        self.bundle = bundle
    }
    
    func localizedString(for key: String, value: String? = nil, table: String? = nil) -> String {
        return bundle.localizedString(forKey: key, value: value ?? key, table: table)
    }
}

// MARK: - Localization Helper
extension String {
    var localized: String {
        LanguageManager.shared.localizedString(for: self, value: self, table: nil)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
