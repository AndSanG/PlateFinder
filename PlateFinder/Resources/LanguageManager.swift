//
//  LanguageManager.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 09/07/2025.
//

import Foundation

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selected_language")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "selected_language") ?? AppConstants.defaultLanguage
    }
    
    func setLanguage(_ language: String) {
        guard AppConstants.supportedLanguages.contains(language) else { return }
        currentLanguage = language
    }
    
    var currentLocale: Locale {
        return Locale(identifier: currentLanguage)
    }
}

// MARK: - Localization Helper
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
