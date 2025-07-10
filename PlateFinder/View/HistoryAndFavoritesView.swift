//
//  HistoryAndFavoritesView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import SwiftUI

struct HistoryAndFavoritesView: View {
    @ObservedObject var viewModel: PlateFinderViewModel
    @Binding var selectedTab: ContentView.AppTab
    @State private var selectedHistoryTab: HistoryTab = .history
    
    enum HistoryTab: String, CaseIterable {
        case history = "history"
        case favorites = "favorites"
        
        var localizedTitle: String {
            return self.rawValue.localized
        }
        
        var icon: String {
            switch self {
            case .history:
                return "clock"
            case .favorites:
                return "star"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom tab picker
                Picker("Tabs", selection: $selectedHistoryTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Label(tab.localizedTitle, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                
                // Content based on selected tab
                switch selectedHistoryTab {
                case .history:
                    historyView
                case .favorites:
                    favoritesView
                }
            }
            .navigationTitle("history_and_favorites".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedHistoryTab == .history && !viewModel.searchHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("clear".localized) {
                            showClearHistoryAlert()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var historyView: some View {
        if viewModel.searchHistory.isEmpty {
            emptyHistoryView
        } else {
            List {
                ForEach(viewModel.searchHistory) { item in
                    SearchHistoryItemView(
                        item: item,
                        onTap: {
                            viewModel.plateNumber = item.plateNumber
                            selectedTab = .search
                        },
                        onDelete: {
                            viewModel.removeFromHistory(item)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var favoritesView: some View {
        if viewModel.favorites.isEmpty {
            emptyFavoritesView
        } else {
            List {
                ForEach(viewModel.favorites, id: \.self) { plateNumber in
                    FavoriteItemView(
                        plateNumber: plateNumber,
                        onTap: {
                            viewModel.plateNumber = plateNumber
                            selectedTab = .search
                        },
                        onDelete: {
                            viewModel.toggleFavorite(plateNumber)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("no_search_history".localized)
                .font(.title2)
                .fontWeight(.medium)
            
            Text("recent_searches_will_appear_here".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private var emptyFavoritesView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("no_favorite_plates".localized)
                .font(.title2)
                .fontWeight(.medium)
            
            Text("mark_plates_as_favorites_for_quick_access".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private func showClearHistoryAlert() {
        let alert = UIAlertController(
            title: "clear_history".localized,
            message: "clear_history_confirmation".localized,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "clear".localized, style: .destructive) { _ in
            viewModel.clearHistory()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

#Preview {
    let viewModel = PlateFinderViewModel(userDataService: MockUserDataService())
    
    // Add some mock data
    let mockService = MockUserDataService()
    mockService.addToHistory(SearchHistoryItem(plateNumber: "ABC1234", car: Car.mock))
    mockService.addToHistory(SearchHistoryItem(plateNumber: "XYZ5678"))
    mockService.addToFavorites("ABC1234")
    mockService.addToFavorites("DEF9876")
    
    return HistoryAndFavoritesView(viewModel: viewModel, selectedTab: .constant(.history))
}
