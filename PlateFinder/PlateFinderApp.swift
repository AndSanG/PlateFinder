import SwiftUI

@main
struct PlateFinderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(IntentHandler.shared)
                .environmentObject(LanguageManager.shared)
        }
    }
}

struct ContentView: View {
    @State private var viewModel: PlateFinderViewModel = {
        let store = UserDefaultsCarStore()
        let loader = RemoteCarInfoLoader(
            url: URL(string: AppConstants.baseURL)!,
            client: URLSessionHTTPClient(),
            parser: ANTHTMLParser()
        )
        return PlateFinderViewModel(loader: loader, store: store, favoritesStore: store)
    }()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTab: AppTab = .search

    enum AppTab { case search, history }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlateSearchView(viewModel: viewModel, selectedTab: $selectedTab)
            }
            .tabItem { Label("search".localized, systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            HistoryAndFavoritesView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem { Label("history".localized, systemImage: "clock") }
                .tag(AppTab.history)
        }
        .id(languageManager.currentLanguage)
    }
}
