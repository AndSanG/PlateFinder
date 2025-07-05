
import Foundation

@MainActor
class IntentHandler: ObservableObject {
    static let shared = IntentHandler()
    @Published var plateToSearch: String?

    private init() {}

    func searchPlate(plate: String) {
        self.plateToSearch = plate
    }
}
