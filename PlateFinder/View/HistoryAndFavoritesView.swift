import SwiftUI

struct HistoryAndFavoritesView: View {
    @Environment(HistoryViewModel.self) private var viewModel
    @Environment(SearchViewModel.self) private var searchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHistoryTab: HistoryTab = .history
    @State private var showClearHistoryAlert = false

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

                switch viewModel.state {
                case .loading:
                    Spacer()
                    ProgressView()
                    Spacer()
                case .loaded(let history, let favorites):
                    switch selectedHistoryTab {
                    case .history:  historyList(history, favorites: favorites)
                    case .favorites: favoritesList(favorites)
                    }
                case .error(let message):
                    Spacer()
                    Text(message).foregroundColor(.red).padding()
                    Spacer()
                }
            }
            .navigationTitle("history_and_favorites".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedHistoryTab == .history,
                   case .loaded(let history, _) = viewModel.state,
                   !history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("clear".localized) { showClearHistoryAlert = true }
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("clear_history".localized, isPresented: $showClearHistoryAlert) {
                Button("clear".localized, role: .destructive) {
                    Task { await viewModel.clearAll() }
                }
                Button("cancel".localized, role: .cancel) { }
            } message: {
                Text("clear_history_confirmation".localized)
            }
            .task { await viewModel.loadData() }
        }
    }

    @ViewBuilder
    private func historyList(_ history: [SearchHistoryItem], favorites: [String]) -> some View {
        if history.isEmpty {
            emptyState(icon: "clock", title: "no_search_history".localized, subtitle: "recent_searches_will_appear_here".localized)
        } else {
            List {
                ForEach(history, id: \.plateNumber) { item in
                    SearchHistoryItemView(
                        item: item,
                        onTap: {
                            if let car = item.car {
                                Task { await searchViewModel.show(car) }
                            } else {
                                Task { await searchViewModel.search(plate: item.plateNumber) }
                            }
                            dismiss()
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
    private func favoritesList(_ favorites: [String]) -> some View {
        if favorites.isEmpty {
            emptyState(icon: "star", title: "no_favorite_plates".localized, subtitle: "mark_plates_as_favorites_for_quick_access".localized)
        } else {
            List {
                ForEach(favorites, id: \.self) { plateNumber in
                    FavoriteItemView(
                        plateNumber: plateNumber,
                        onTap: {
                            Task { await searchViewModel.search(plate: plateNumber) }
                            dismiss()
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
}
