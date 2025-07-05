//
//  PlateFinderApp.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 01/07/2025.
//

import SwiftUI

@main
struct PlateFinderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(IntentHandler.shared)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PlateFinderViewModel()
    @State private var selectedTab: AppTab = .search
    
    enum AppTab {
        case search
        case history
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlateSearchView(viewModel: viewModel, selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Buscar", systemImage: "magnifyingglass")
            }
            .tag(AppTab.search)
            
            HistoryAndFavoritesView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Historial", systemImage: "clock")
                }
                .tag(AppTab.history)
        }
    }
}
