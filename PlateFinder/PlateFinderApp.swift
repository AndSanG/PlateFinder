import SwiftUI

@main
struct PlateFinderApp: App {
    @State private var searchViewModel: SearchViewModel
    @State private var historyViewModel: HistoryViewModel
    @State private var intentRouter: IntentRouter
    @State private var appRouter: AppRouter
    @State private var intentCoordinator: IntentSearchCoordinator
    @Environment(\.scenePhase) private var scenePhase

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
        CarPlayDependencyBridge.shared.intentRouter = router

        let searchVM = SearchViewModel(
            loadCarInfo: carInfoService,
            addToHistory: HistoryAdder(store: store)
        )
        let sessionStore = UserDefaultsChatSessionStore()
        let historyVM = HistoryViewModel(
            loadHistory: HistoryLoader(store: store),
            loadFavorites: FavoritesLoader(store: store),
            deleteFromHistory: HistoryDeleter(store: store),
            clearHistory: HistoryClearer(store: store),
            toggleFavorite: FavoritesToggler(store: store),
            loadChatCutoff: ChatCutoffLoader(store: sessionStore),
            saveChatCutoff: ChatCutoffSaver(store: sessionStore),
            loadLastSessionEnd: LastSessionEndLoader(store: sessionStore),
            saveLastSessionEnd: LastSessionEndSaver(store: sessionStore)
        )
        CarPlayDependencyBridge.shared.searchViewModel = searchVM
        CarPlayDependencyBridge.shared.historyViewModel = historyVM
        _searchViewModel = State(initialValue: searchVM)
        _historyViewModel = State(initialValue: historyVM)
        _intentRouter = State(initialValue: router)
        _appRouter = State(initialValue: AppRouter())
        _intentCoordinator = State(initialValue: IntentSearchCoordinator(
            intentRouter: router,
            searchViewModel: searchVM
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(searchViewModel)
                .environment(historyViewModel)
                .environment(intentRouter)
                .environment(appRouter)
                .environment(intentCoordinator)
        }
    }
}

struct ContentView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(SearchViewModel.self) private var searchViewModel
    @Environment(HistoryViewModel.self) private var historyViewModel
    @Environment(IntentSearchCoordinator.self) private var intentCoordinator
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = appRouter
        PlateSearchView()
            .environment(\.defaultMinListRowHeight, 60)
            .sheet(isPresented: $router.isHistoryPresented) {
                HistoryAndFavoritesView()
                    .environment(\.defaultMinListRowHeight, 60)
                    .presentationDetents([.medium, .large])
            }
            // Start the observation loop that dispatches Siri / App Intent searches.
            .task { intentCoordinator.start() }
            // Cold launch: returning after a long absence starts a new chat.
            .task { await startNewChatIfExpired() }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    Task { await startNewChatIfExpired() }
                case .background:
                    Task { await historyViewModel.recordSessionEnd() }
                default:
                    break
                }
            }
            .onChange(of: intentCoordinator.lastRequest) { _, request in
                // An incoming Siri/App Intent search must be visible immediately,
                // even if the history sheet is covering the search screen.
                if request != nil { appRouter.isHistoryPresented = false }
            }
    }

    private func startNewChatIfExpired() async {
        if await historyViewModel.clearChatIfExpired() {
            searchViewModel.reset()
        }
    }
}
