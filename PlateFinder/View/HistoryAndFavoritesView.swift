import SwiftUI

struct HistoryAndFavoritesView: View {
    var viewModel: PlateFinderViewModel
    @Binding var selectedTab: ContentView.AppTab
    @State private var selectedHistoryTab: HistoryTab = .history

    enum HistoryTab: String, CaseIterable {
        case history, favorites
        var localizedTitle: String { rawValue.localized }
        var icon: String { self == .history ? "clock" : "star" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tabs", selection: $selectedHistoryTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Label(tab.localizedTitle, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                switch selectedHistoryTab {
                case .history:  historyView
                case .favorites: favoritesView
                }
            }
            .navigationTitle("history_and_favorites".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedHistoryTab == .history && !viewModel.history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("clear".localized) { showClearHistoryAlert() }
                            .foregroundColor(.red)
                    }
                }
            }
            .task { await viewModel.loadHistory(); await viewModel.loadFavorites() }
        }
    }

    @ViewBuilder
    private var historyView: some View {
        if viewModel.history.isEmpty {
            emptyState(icon: "clock", title: "no_search_history".localized, subtitle: "recent_searches_will_appear_here".localized)
        } else {
            List {
                ForEach(viewModel.history, id: \.plateNumber) { item in
                    SearchHistoryItemView(
                        item: item,
                        onTap: {
                            Task { await viewModel.select(item) }
                            selectedTab = .search
                        },
                        onDelete: { Task { await viewModel.delete(item) } }
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
            emptyState(icon: "star", title: "no_favorite_plates".localized, subtitle: "mark_plates_as_favorites_for_quick_access".localized)
        } else {
            List {
                ForEach(viewModel.favorites, id: \.self) { plateNumber in
                    FavoriteItemView(
                        plateNumber: plateNumber,
                        onTap: {
                            viewModel.plateText = plateNumber
                            selectedTab = .search
                            Task { await viewModel.search() }
                        },
                        onDelete: { Task { await viewModel.toggleFavorite(plateNumber) } }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon).font(.system(size: 60)).foregroundColor(.gray)
            Text(title).font(.title2).fontWeight(.medium)
            Text(subtitle).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
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
            Task { await viewModel.deleteAllHistory() }
        })
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

#Preview {
    let store = UserDefaultsCarStore(defaults: .init(suiteName: "preview")!)
    let loader = RemoteCarInfoLoader(
        url: URL(string: AppConstants.baseURL)!,
        client: URLSessionHTTPClient(),
        parser: ANTHTMLParser()
    )
    HistoryAndFavoritesView(
        viewModel: PlateFinderViewModel(loader: loader, store: store, favoritesStore: store),
        selectedTab: .constant(.history)
    )
}
