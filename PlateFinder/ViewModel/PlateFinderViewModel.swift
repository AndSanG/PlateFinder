//
//  PlateFinderViewModel.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import Foundation
import SwiftUI
import SwiftSoup

enum Stage {
    case idle
    case loading
    case loaded(car: Car)
    case error(Error)
}

@MainActor
class PlateFinderViewModel: ObservableObject{
    @Published var plateNumber: String = ""
    @Published var isTesting = false
    @Published var stage: Stage = .idle
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var favorites: [String] = []
    
    let service = CarInfoService()
    private let userDataService: UserDataServiceProtocol
    
    init(userDataService: UserDataServiceProtocol = UserDataService.shared) {
        self.userDataService = userDataService
        loadUserData()
    }
    
    private func loadUserData() {
        searchHistory = userDataService.getHistory()
        favorites = userDataService.getFavorites()
    }
    
    func getCarInfo() async {
        self.stage = .loading
        
        do {
            let car = try await service.getCarInfo(with: plateNumber, isTesting: isTesting)
            
            // Add to search history with car data
            let historyItem = SearchHistoryItem(plateNumber: plateNumber, car: car)
            userDataService.addToHistory(historyItem)
            loadUserData() // Refresh the published properties
            
            self.stage = .loaded(car: car)
        } catch let error as CarInfoError {
            print("A specific error occurred: \(error.localizedDescription)")
            
            // Add to search history even if failed (without car data)
            let historyItem = SearchHistoryItem(plateNumber: plateNumber)
            userDataService.addToHistory(historyItem)
            loadUserData()
            
            self.stage = .error(error)
        } catch {
            self.stage = .error(error)
            print("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Search History Methods
    
    func searchFromHistory(_ historyItem: SearchHistoryItem) {
        plateNumber = historyItem.plateNumber
        
        // If we have cached car data, use it directly
        if let car = historyItem.car {
            stage = .loaded(car: car)
            // Update history to move this item to top
            let updatedItem = SearchHistoryItem(plateNumber: historyItem.plateNumber, car: car)
            userDataService.addToHistory(updatedItem)
            loadUserData()
        } else {
            // Fetch fresh data
            Task {
                await getCarInfo()
            }
        }
    }
    
    func removeFromHistory(_ historyItem: SearchHistoryItem) {
        userDataService.removeFromHistory(historyItem)
        loadUserData()
    }
    
    func clearHistory() {
        userDataService.clearHistory()
        loadUserData()
    }
    
    // MARK: - Favorites Methods
    
    func toggleFavorite(_ plateNumber: String) {
        userDataService.toggleFavorite(plateNumber)
        loadUserData()
    }
    
    func isFavorite(_ plateNumber: String) -> Bool {
        return userDataService.isFavorite(plateNumber)
    }
    
    func searchFromFavorite(_ plateNumber: String) {
        self.plateNumber = plateNumber
        Task {
            await getCarInfo()
        }
    }
}
