import CarPlay

@MainActor
final class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    private var coordinator: CarPlayCoordinator?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        guard
            let searchVM = CarPlayDependencyBridge.shared.searchViewModel,
            let historyVM = CarPlayDependencyBridge.shared.historyViewModel,
            let router = CarPlayDependencyBridge.shared.intentRouter
        else { return }

        coordinator = CarPlayCoordinator(
            interfaceController: interfaceController,
            searchViewModel: searchVM,
            historyViewModel: historyVM,
            intentRouter: router
        )
        coordinator?.start()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        coordinator = nil
    }
}
