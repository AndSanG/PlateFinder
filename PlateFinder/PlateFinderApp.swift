import SwiftUI

@main
struct PlateFinderApp: App {
    @State private var searchViewModel: SearchViewModel
    @State private var historyViewModel: HistoryViewModel
    @State private var intentRouter: IntentRouter
    @State private var appRouter: AppRouter

    init() {
        let store = UserDefaultsCarStore()
        let carInfoService = ANTCarInfoService(
            url: URL(string: AppConstants.baseURL)!,
            client: URLSessionHTTPClient(),
            mapper: ANTCarHTMLMapper()
        )
        let router = IntentRouter()
        AppIntentIntentRouterBridge.shared.router = router
        PlateFinderShortcuts.updateAppShortcutParameters()

        _searchViewModel = State(initialValue: SearchViewModel(
            loadCarInfo: carInfoService,
            addToHistory: HistoryAdder(store: store)
        ))
        _historyViewModel = State(initialValue: HistoryViewModel(
            loadHistory: HistoryLoader(store: store),
            loadFavorites: FavoritesLoader(store: store),
            deleteFromHistory: HistoryDeleter(store: store),
            clearHistory: HistoryClearer(store: store),
            toggleFavorite: FavoritesToggler(store: store)
        ))
        _intentRouter = State(initialValue: router)
        _appRouter = State(initialValue: AppRouter())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(searchViewModel)
                .environment(historyViewModel)
                .environment(intentRouter)
                .environment(appRouter)
        }
    }
}

struct ContentView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(IntentRouter.self) private var intentRouter
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = appRouter
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                PlateSearchView()
            }
            .tabItem { Label("search".localized, systemImage: "magnifyingglass") }
            .tag(AppRouter.Tab.search)

            HistoryAndFavoritesView()
                .tabItem { Label("history".localized, systemImage: "clock") }
                .tag(AppRouter.Tab.history)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active,
                  let plate = UserDefaults.standard.string(forKey: "pendingIntentPlate")
            else { return }
            UserDefaults.standard.removeObject(forKey: "pendingIntentPlate")
            intentRouter.requestSearch(plate: plate)
        }
    }
}
