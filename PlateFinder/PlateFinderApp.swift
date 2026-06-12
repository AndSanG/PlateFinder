import SwiftUI

@main
struct PlateFinderApp: App {
    @State private var searchViewModel: SearchViewModel
    @State private var historyViewModel: HistoryViewModel
    @State private var intentRouter: IntentRouter
    @State private var appRouter: AppRouter
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

        _searchViewModel = State(initialValue: SearchViewModel(
            loadCarInfo: carInfoService,
            addToHistory: HistoryAdder(store: store)
        ))
        let sessionStore = UserDefaultsChatSessionStore()
        _historyViewModel = State(initialValue: HistoryViewModel(
            loadHistory: HistoryLoader(store: store),
            loadFavorites: FavoritesLoader(store: store),
            deleteFromHistory: HistoryDeleter(store: store),
            clearHistory: HistoryClearer(store: store),
            toggleFavorite: FavoritesToggler(store: store),
            loadChatCutoff: ChatCutoffLoader(store: sessionStore),
            saveChatCutoff: ChatCutoffSaver(store: sessionStore),
            loadLastSessionEnd: LastSessionEndLoader(store: sessionStore),
            saveLastSessionEnd: LastSessionEndSaver(store: sessionStore)
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
    @Environment(SearchViewModel.self) private var searchViewModel
    @Environment(HistoryViewModel.self) private var historyViewModel
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
            // Cold launch: returning after a long absence starts a new chat.
            .task { await startNewChatIfExpired() }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    Task { await startNewChatIfExpired() }
                    guard let plate = UserDefaults.standard.string(forKey: "pendingIntentPlate")
                    else { return }
                    UserDefaults.standard.removeObject(forKey: "pendingIntentPlate")
                    intentRouter.requestSearch(plate: plate)
                case .background:
                    Task { await historyViewModel.recordSessionEnd() }
                default:
                    break
                }
            }
            .onChange(of: intentRouter.pendingPlate) { _, pending in
                // An incoming Siri/App Intent search must be visible immediately,
                // even if the history sheet is covering the search screen.
                if pending != nil { appRouter.isHistoryPresented = false }
            }
    }

    /// Auto "new chat": when the user comes back after the session timeout,
    /// soft-clear the conversation and drop any lingering result bubble.
    private func startNewChatIfExpired() async {
        if await historyViewModel.clearChatIfExpired() {
            searchViewModel.reset()
        }
    }
}
