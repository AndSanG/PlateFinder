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
    @State private var showLanguageSettings = false
    
    enum AppTab {
        case search
        case history
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlateSearchView(viewModel: viewModel, selectedTab: $selectedTab)
            }
            .tabItem {
                Label("search".localized, systemImage: "magnifyingglass")
            }
            .tag(AppTab.search)
            
            HistoryAndFavoritesView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("history".localized, systemImage: "clock")
                }
                .tag(AppTab.history)
            
            NavigationStack {
                SettingsView(showLanguageSettings: $showLanguageSettings)
            }
            .tabItem {
                Label("settings".localized, systemImage: "gear")
            }
            .tag(AppTab.settings)
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageSettingsView()
        }
    }
}
