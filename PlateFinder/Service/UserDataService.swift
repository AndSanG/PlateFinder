//
//  UserDataService.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import Foundation

protocol UserDataServiceProtocol {
    func addToHistory(_ item: SearchHistoryItem)
    func getHistory() -> [SearchHistoryItem]
    func clearHistory()
    func removeFromHistory(_ item: SearchHistoryItem)
    
    func addToFavorites(_ plateNumber: String)
    func removeFromFavorites(_ plateNumber: String)
    func getFavorites() -> [String]
    func isFavorite(_ plateNumber: String) -> Bool
    func toggleFavorite(_ plateNumber: String)
}

class UserDataService: UserDataServiceProtocol {
    static let shared = UserDataService()
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "search_history"
    private let favoritesKey = "favorites"
    private let maxHistoryItems = 50
    
    private init() {}
    
    // MARK: - Search History
    
    func addToHistory(_ item: SearchHistoryItem) {
        var history = getHistory()
        
        // Remove existing item with same plate number to avoid duplicates
        history.removeAll { $0.plateNumber == item.plateNumber }
        
        // Add new item at the beginning
        history.insert(item, at: 0)
        
        // Limit history size
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        saveHistory(history)
    }
    
    func getHistory() -> [SearchHistoryItem] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            return []
        }
        return history
    }
    
    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }
    
    func removeFromHistory(_ item: SearchHistoryItem) {
        var history = getHistory()
        history.removeAll { $0.plateNumber == item.plateNumber }
        saveHistory(history)
    }
    
    private func saveHistory(_ history: [SearchHistoryItem]) {
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    // MARK: - Favorites
    
    func addToFavorites(_ plateNumber: String) {
        var favorites = getFavorites()
        if !favorites.contains(plateNumber) {
            favorites.append(plateNumber)
            saveFavorites(favorites)
        }
    }
    
    func removeFromFavorites(_ plateNumber: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == plateNumber }
        saveFavorites(favorites)
    }
    
    func getFavorites() -> [String] {
        return userDefaults.stringArray(forKey: favoritesKey) ?? []
    }
    
    func isFavorite(_ plateNumber: String) -> Bool {
        return getFavorites().contains(plateNumber)
    }
    
    func toggleFavorite(_ plateNumber: String) {
        if isFavorite(plateNumber) {
            removeFromFavorites(plateNumber)
        } else {
            addToFavorites(plateNumber)
        }
    }
    
    private func saveFavorites(_ favorites: [String]) {
        userDefaults.set(favorites, forKey: favoritesKey)
    }
}

// MARK: - Mock Service for Testing

class MockUserDataService: UserDataServiceProtocol {
    private var history: [SearchHistoryItem] = []
    private var favorites: [String] = []
    
    func addToHistory(_ item: SearchHistoryItem) {
        history.removeAll { $0.plateNumber == item.plateNumber }
        history.insert(item, at: 0)
    }
    
    func getHistory() -> [SearchHistoryItem] {
        return history
    }
    
    func clearHistory() {
        history.removeAll()
    }
    
    func removeFromHistory(_ item: SearchHistoryItem) {
        history.removeAll { $0.plateNumber == item.plateNumber }
    }
    
    func addToFavorites(_ plateNumber: String) {
        if !favorites.contains(plateNumber) {
            favorites.append(plateNumber)
        }
    }
    
    func removeFromFavorites(_ plateNumber: String) {
        favorites.removeAll { $0 == plateNumber }
    }
    
    func getFavorites() -> [String] {
        return favorites
    }
    
    func isFavorite(_ plateNumber: String) -> Bool {
        return favorites.contains(plateNumber)
    }
    
    func toggleFavorite(_ plateNumber: String) {
        if isFavorite(plateNumber) {
            removeFromFavorites(plateNumber)
        } else {
            addToFavorites(plateNumber)
        }
    }
}
