import CarPlay
import Observation

@MainActor
final class CarPlayCoordinator {
    private let interfaceController: CPInterfaceController
    private let searchViewModel: SearchViewModel
    private let historyViewModel: HistoryViewModel
    private let intentRouter: IntentRouter
    private var lastPlate = ""
    private var observationTask: Task<Void, Never>?

    init(
        interfaceController: CPInterfaceController,
        searchViewModel: SearchViewModel,
        historyViewModel: HistoryViewModel,
        intentRouter: IntentRouter
    ) {
        self.interfaceController = interfaceController
        self.searchViewModel = searchViewModel
        self.historyViewModel = historyViewModel
        self.intentRouter = intentRouter
    }

    func start() {
        renderCurrent()
        Task { await historyViewModel.loadData() }
        observationTask = Task { [weak self] in await self?.loop() }
    }

    // MARK: - Observation loop

    private func loop() async {
        while !Task.isCancelled {
            await waitForChange()
            renderCurrent()
        }
    }

    private func waitForChange() async {
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
            withObservationTracking {
                _ = searchViewModel.state
                _ = historyViewModel.state
            } onChange: {
                continuation.resume()
            }
        }
    }

    // MARK: - Rendering

    private func renderCurrent() {
        let screen = CarPlayScreenBuilder.build(
            state: searchViewModel.state,
            lastPlate: lastPlate,
            history: currentHistory()
        )

        switch screen {
        case .recentSearches(let rows):
            interfaceController.setRootTemplate(makeListTemplate(rows: rows), animated: true, completion: nil)

        case .loading(let plate):
            let items = [CPInformationItem(title: NSLocalizedString("consulting_ant_database", comment: ""), detail: plate)]
            let template = CPInformationTemplate(title: plate, layout: .twoColumn, items: items, actions: [])
            interfaceController.setRootTemplate(template, animated: false, completion: nil)

        case .result(let title, let detailRows):
            let items = detailRows.map {
                CPInformationItem(title: NSLocalizedString($0.labelKey, comment: ""), detail: $0.value)
            }
            let ok = CPTextButton(title: NSLocalizedString("ok", comment: ""), textStyle: .confirm) { [weak self] _ in
                Task { @MainActor [weak self] in self?.searchViewModel.reset() }
            }
            let template = CPInformationTemplate(title: title, layout: .twoColumn, items: items, actions: [ok])
            interfaceController.setRootTemplate(template, animated: true, completion: nil)

        case .error(let messageKey):
            let ok = CPAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .default
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.searchViewModel.reset() }
            }
            let alert = CPAlertTemplate(
                titleVariants: [NSLocalizedString(messageKey, comment: "")],
                actions: [ok]
            )
            interfaceController.presentTemplate(alert, animated: true, completion: nil)
        }
    }

    private func makeListTemplate(rows: [CarPlayScreen.Row]) -> CPListTemplate {
        let items: [CPListItem]
        if rows.isEmpty {
            items = [CPListItem(text: NSLocalizedString("carplay_no_history", comment: ""), detailText: nil)]
        } else {
            items = rows.map { row in
                let item = CPListItem(text: row.title, detailText: row.subtitle)
                let plate = row.plate
                item.handler = { [weak self] _, completion in
                    Task { @MainActor [weak self] in
                        self?.lastPlate = plate
                        await self?.searchViewModel.search(plate: plate)
                    }
                    completion()
                }
                return item
            }
        }
        return CPListTemplate(title: "PlateFinder", sections: [CPListSection(items: items)])
    }

    private func currentHistory() -> [SearchHistoryItem] {
        guard case .loaded(let history, _) = historyViewModel.state else { return [] }
        return history
    }
}
