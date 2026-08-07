# PlateFinder — Module Map & Protocol Contracts

For the hard rules (forbidden imports, DI, concurrency, testing, commit discipline) see [architecture.md](architecture.md). This document is the concrete map of what lives where and the protocol contracts between layers.

---

## Module Boundaries

### 1. `PlateFinderDomain` — macOS Framework (Domain Layer)

Targets **macOS 15+ only** so all domain, use-case, and ViewModel tests run natively without an iOS Simulator boot.

**Allowed imports:** `Foundation`, `Observation`
**Forbidden imports:** `UIKit`, `SwiftUI`, `AppKit`, `AppIntents`, `Combine`, `CoreData`, `SwiftData`, `Security`, `SwiftSoup`, any networking library

Contains:
- **Entities**: `Car`, `SearchHistoryItem`, `PlateFormat`, `CarInfoError`
- **Domain logic**: `PlateValidator` (pure)
- **Use Case protocols**: `LoadCarInfo`, `LoadHistory`, `AddToHistory`, `DeleteFromHistory`, `ClearHistory`, `LoadFavorites`, `ToggleFavorite`, plus the chat-session markers `LoadChatCutoff`, `SaveChatCutoff`, `LoadLastSessionEnd`, `SaveLastSessionEnd`
- **Repository protocols**: `HTTPClient`, `CarHTMLMapper`, `CarStore`, `FavoritesStore`
- **Presentation state**: per-screen `ViewState` enums (`SearchViewState`, `HistoryViewState`)
- **ViewModels**: `SearchViewModel`, `HistoryViewModel` (each `@Observable @MainActor final class`, single `private(set) var state`)
- **Routers**: `IntentRouter` (`@Observable`), `AppRouter` (`@Observable`, owns history-sheet presentation)
- **Intent dispatch**: `IntentSearchCoordinator` (`@Observable @MainActor`), a `withObservationTracking` re-arm loop over `IntentRouter.pendingPlate` that runs a search whichever scene is active, including CarPlay-only launches
- **CarPlay presentation state**: `CarPlayScreen` (enum with `Row` / `DetailRow` payloads) and `CarPlayScreenBuilder`, a pure `SearchViewState` to `CarPlayScreen` mapping. The builder is pure so CarPlay rendering is testable on macOS without the `CarPlay` framework, which Domain may not import

### 2. `PlateFinder` — iOS App Target (Data Layer + Presentation Layer + Composition Root)

Hosts all concrete adapters and the SwiftUI tree.

**Allowed imports:** anything
**Rule:** No type in this target may be referenced by `PlateFinderDomain`. The dependency arrow points app → domain only.

Contains:
- **Data Layer** (`Infrastructure/`):
  - `URLSessionHTTPClient` — conforms to `HTTPClient`
  - `ANTCarInfoService` — conforms to `LoadCarInfo`; fetches HTML via `HTTPClient`, maps via `ANTCarHTMLMapper`
  - `ANTCarHTMLMapper` — conforms to `CarHTMLMapper`; SwiftSoup-based, DTO → `Car`
  - `UserDefaultsCarStore` — conforms to `CarStore` + `FavoritesStore`
  - `UserDefaultsHistoryUseCases` — conforms to `LoadHistory` / `AddToHistory` / `DeleteFromHistory` / `ClearHistory`, delegating to `CarStore`
  - `UserDefaultsFavoritesUseCases` — conforms to `LoadFavorites` / `ToggleFavorite`, delegating to `FavoritesStore`
  - `UserDefaultsChatSessionStore` plus `ChatCutoffLoader` / `ChatCutoffSaver` / `LastSessionEndLoader` / `LastSessionEndSaver`, which conform to the four chat-session use cases
  - `SpeechRecognizer` (`@Observable @MainActor`): wraps `Speech` + `AVFoundation` for plate dictation, auto-stopping after 10 seconds. App-target only, since Domain may not import either framework
  - `Car+Codable`, `SearchHistoryItem+Codable` — infrastructure-only extensions
  - `CarInfoError+LocalizedError` — UI-facing string mapping
- **CarPlay** (`CarPlay/`):
  - `CarPlaySceneDelegate`: `CPTemplateApplicationSceneDelegate`; builds a `CarPlayCoordinator` on connect, drops it on disconnect
  - `CarPlayCoordinator` (`@MainActor`): observes `SearchViewModel.state` / `HistoryViewModel.state`, maps each change through `CarPlayScreenBuilder`, and renders the resulting `CarPlayScreen` as `CPTemplate`s
  - `CarPlayDependencyBridge`: hands the Composition Root's live ViewModels to the scene delegate (see the entry-point note under Dependency Injection in [architecture.md](architecture.md))
- **Presentation Layer** (`View/`): pure SwiftUI views, `NavigationStack`-based routing, exhaustive `switch` over `ViewState`
- **Composition Root** (`PlateFinderApp.swift`): constructs every concrete type, injects them into ViewModels/Routers, publishes shared dependencies via `.environment(...)`
- **AppIntents** (`Intents/`): `FindPlateIntent`, `PlateFinderShortcuts`; route through `IntentRouter` (not via singleton)
- **App constants** (`Globals.swift`): `AppConstants` (base ANT URL, UI constants) and `NetworkConfig` (default encoding). App-target only — never imported from Domain
- **Localization** (`Resources/LanguageManager.swift`): the `String.localized` extension that wraps `NSLocalizedString`. App-target only. (`.lproj/` bundles live alongside.) The legacy `LanguageManager: ObservableObject` documented in `README_Localization.md` is **not** present in code; if reintroduced, it must be a `@Observable` `final class` injected via `.environment(...)`, never an `@EnvironmentObject`

### 3. Test Bundles

All three are **macOS** bundles (`SDKROOT = macosx`, no `TEST_HOST`), so the whole suite runs at `swift test` speed with no Simulator boot.

| Bundle | Sources | Tests |
|---|---|---|
| `PlateFinderTests` | links `PlateFinderDomain.framework` | `PlateValidator`, `SearchViewModel`, `HistoryViewModel`, `CarPlayScreenBuilder`, `IntentSearchCoordinator` (78 cases) |
| `PlateFinderInfraTests` | compiles the sources under test directly (`URLSessionHTTPClient.swift`, `ANTCarInfoService.swift`, plus `Car`/`CarInfoError`/`CarInfoLoader`) rather than linking the app target, which would drag in SwiftSoup and UIKit | `URLSessionHTTPClient` and `ANTCarInfoService` via URLProtocol stubs (14 cases) |
| `PlateFinderAPIEndToEndTests` | same direct-compile approach | Hits the live ANT endpoint; verifies the full pipeline |

`ANTCarHTMLMapper` and `UserDefaultsCarStore` currently have **no tests**: both are reachable only through the app target, so covering them means either giving the infra bundle a SwiftSoup dependency or moving the parsing logic behind a seam the bundle can compile on its own.

All bundles use Swift Testing (`import Testing`); none use XCTest.

### Which bundles CI runs

The `PlateFinderTests` scheme builds and runs **both** `PlateFinderTests` and `PlateFinderInfraTests`, and `fastlane unit_tests` invokes that one scheme. `PlateFinderAPIEndToEndTests` has its own scheme and is deliberately excluded, since it depends on the live ANT portal.

Do not re-enable Thread Sanitizer on this scheme. macOS xctest bundles are loaded via `dlopen`, so TSan cannot install its interceptors and the runner aborts before executing a single test, with a bare `abort()` that does not name the sanitizer as the cause.

---

## Dependency Direction

```
PlateFinder (iOS App Target)
│
│  Composition Root wires concrete adapters:
│    URLSessionHTTPClient            ──► HTTPClient
│    ANTCarHTMLMapper                ──► CarHTMLMapper
│    ANTCarInfoService               ──► LoadCarInfo
│    UserDefaultsCarStore            ──► CarStore + FavoritesStore
│    UserDefaultsHistoryUseCases     ──► LoadHistory / AddToHistory / …
│    UserDefaultsFavoritesUseCases   ──► LoadFavorites / ToggleFavorite
│    UserDefaultsChatSessionStore    ──► LoadChatCutoff / SaveChatCutoff /
│                                        LoadLastSessionEnd / SaveLastSessionEnd
│
│  SwiftUI views switch over:
│    SearchViewModel.state : SearchViewState
│    HistoryViewModel.state : HistoryViewState
│
│  CarPlayCoordinator renders:
│    CarPlayScreenBuilder.build(state:…) : CarPlayScreen ──► CPTemplate
│
└─────────────────────────────────────┐
                                      │ depends on (protocols + entities only)
                                      ▼
                  PlateFinderDomain (macOS Framework)
                  ┌──────────────────────────────────┐
                  │  Entities                        │
                  │    Car, SearchHistoryItem,       │
                  │    PlateFormat, CarInfoError     │
                  │                                  │
                  │  Domain logic                    │
                  │    PlateValidator                │
                  │                                  │
                  │  Use Case protocols              │
                  │    LoadCarInfo                   │
                  │    LoadHistory / AddToHistory /  │
                  │    DeleteFromHistory / Clear…    │
                  │    LoadFavorites / ToggleFav…    │
                  │    Load/SaveChatCutoff           │
                  │    Load/SaveLastSessionEnd       │
                  │                                  │
                  │  Repository protocols            │
                  │    HTTPClient, CarHTMLMapper,    │
                  │    CarStore, FavoritesStore      │
                  │                                  │
                  │  Presentation state              │
                  │    SearchViewState               │
                  │    HistoryViewState              │
                  │    CarPlayScreen                 │
                  │      + CarPlayScreenBuilder      │
                  │                                  │
                  │  ViewModels (@Observable)        │
                  │    SearchViewModel               │
                  │    HistoryViewModel              │
                  │                                  │
                  │  Routers (@Observable)           │
                  │    IntentRouter, AppRouter       │
                  │    IntentSearchCoordinator       │
                  └──────────────────────────────────┘
```

Arrows never point from the domain framework toward the app target.

---

## Protocol Contracts

All methods are `async throws` (iOS 17+). All `Sendable` where they cross actor boundaries.

### Repository protocols (Data Layer implements these)

```swift
protocol HTTPClient: Sendable {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

protocol CarHTMLMapper: Sendable {
    func map(_ html: String) throws -> Car
}

protocol CarStore: Sendable {
    func retrieve() async throws -> [SearchHistoryItem]
    func insert(_ item: SearchHistoryItem) async throws
    func delete(_ item: SearchHistoryItem) async throws
    func deleteAll() async throws
}

protocol FavoritesStore: Sendable {
    func retrieveFavorites() async throws -> [String]
    func insertFavorite(_ plateNumber: String) async throws
    func deleteFavorite(_ plateNumber: String) async throws
}
```

### Use Case protocols (ViewModels depend on these only)

Each is a single-method protocol — Interface Segregation by intent.

```swift
protocol LoadCarInfo: Sendable {
    func execute(plate: String) async throws -> Car
}

protocol LoadHistory: Sendable {
    func execute() async throws -> [SearchHistoryItem]
}

protocol AddToHistory: Sendable {
    func execute(_ item: SearchHistoryItem) async throws
}

protocol DeleteFromHistory: Sendable {
    func execute(_ item: SearchHistoryItem) async throws
}

protocol ClearHistory: Sendable {
    func execute() async throws
}

protocol LoadFavorites: Sendable {
    func execute() async throws -> [String]
}

protocol ToggleFavorite: Sendable {
    func execute(plate: String) async throws -> [String]   // returns the new favorites list
}

// Chat-session markers. The cutoff drives the "soft clear": searches at or
// before it stay in the store and the history list, but drop out of the
// conversation. The last-session-end instant drives the auto "new chat".
protocol LoadChatCutoff: Sendable {
    func execute() async throws -> Date?
}

protocol SaveChatCutoff: Sendable {
    func execute(_ date: Date) async throws
}

protocol LoadLastSessionEnd: Sendable {
    func execute() async throws -> Date?
}

protocol SaveLastSessionEnd: Sendable {
    func execute(_ date: Date) async throws
}
```

ViewModels receive these as `any LoadCarInfo`, `any LoadHistory`, etc. — never `CarStore`/`FavoritesStore` directly.

### Routers (Domain)

```swift
@Observable @MainActor
public final class IntentRouter {
    public private(set) var pendingPlate: String?
    public init() {}
    public func requestSearch(plate: String) { pendingPlate = plate }
    public func consume() { pendingPlate = nil }
}

@Observable @MainActor
public final class AppRouter {
    public var isHistoryPresented = false
    public init() {}
}
```

`AppIntents` calls `IntentRouter.requestSearch(plate:)` via the instance injected at the Composition Root. Replaces the legacy `IntentHandler.shared` singleton + `@Published` pattern.

Dispatch is **not** done by the views. `IntentSearchCoordinator` owns it:

```swift
@Observable @MainActor
public final class IntentSearchCoordinator {
    public struct Request: Equatable { public let id: UUID; public let plate: String }
    public private(set) var lastRequest: Request?
    public init(intentRouter: IntentRouter, searchViewModel: SearchViewModel)
    public func start()   // re-arming withObservationTracking loop
}
```

`start()` spawns a loop that awaits a change to `pendingPlate`, calls `consume()`, publishes a fresh `Request` (the `UUID` makes two searches for the same plate distinguishable), and runs `SearchViewModel.search(plate:)`. Keeping this off the view layer is what lets a Siri search work when CarPlay is the only connected scene, since no SwiftUI view is alive to observe anything. `ContentView` watches `lastRequest` only to dismiss the history sheet so the incoming result is visible.

---

## Presentation State (Domain)

```swift
enum SearchViewState: Equatable {
    case idle
    case loading
    case success(Car)
    case error(String)
}

enum HistoryViewState: Equatable {
    case loading
    case loaded(history: [SearchHistoryItem], favorites: [String])
    case error(String)
}

// CarPlay renders from its own state enum rather than from SwiftUI views.
enum CarPlayScreen: Equatable {
    struct Row: Equatable, Sendable { let title: String; let subtitle: String?; let plate: String }
    struct DetailRow: Equatable, Sendable { let labelKey: String; let value: String }

    case recentSearches([Row])
    case loading(plate: String)
    case result(title: String, detailRows: [DetailRow])
    case error(messageKey: String)
}
```

ViewModels expose `public private(set) var state: …`. Views render via exhaustive `switch viewModel.state`.

`HistoryViewModel` additionally exposes `public private(set) var chatCutoff: Date?`. It is a separate property rather than a `HistoryViewState` case because it is orthogonal to loading: a cutoff applies equally to a loaded list, and the conversation filters on it while the history sheet ignores it.

`CarPlayScreenBuilder.build(state:lastPlate:history:)` maps `SearchViewState` to `CarPlayScreen` as a pure function. `CarPlayCoordinator` turns the result into `CPTemplate`s and does the `NSLocalizedString` lookups, which is why `CarPlayScreen` carries `labelKey` / `messageKey` rather than resolved strings: Domain has no bundle to localize against.

### Reference Pattern

```swift
@Observable @MainActor
final class SearchViewModel {
    public private(set) var state: SearchViewState = .idle
    private let loadCarInfo: any LoadCarInfo
    private let addToHistory: any AddToHistory

    public init(loadCarInfo: any LoadCarInfo, addToHistory: any AddToHistory) {
        self.loadCarInfo = loadCarInfo
        self.addToHistory = addToHistory
    }

    public func search(plate: String) async {
        state = .loading
        do {
            let car = try await loadCarInfo.execute(plate: plate)
            // History write is non-fatal and unsurfaced: a successful lookup must reach the user
            // even if persistence fails. Re-evaluate if history reliability ever becomes load-bearing.
            try? await addToHistory.execute(SearchHistoryItem(plateNumber: plate, searchDate: Date(), car: car))
            state = .success(car)
        } catch let e as CarInfoError {
            state = .error(e.userMessage)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func reset() { state = .idle }
}

struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    @State private var plate = ""

    var body: some View {
        switch viewModel.state {
        case .idle:               PlateInputView(plate: $plate, onSubmit: { Task { await viewModel.search(plate: plate) } })
        case .loading:            ProgressView()
        case .success(let car):   CarDetailView(car: car, onReset: viewModel.reset)
        case .error(let message): ErrorView(message: message, onRetry: viewModel.reset)
        }
    }
}
```

---

## External Endpoints

The single external system is Ecuador's ANT vehicle registry portal.

| Aspect | Value | Where it lives |
|---|---|---|
| Base URL | `https://consultaweb.ant.gob.ec/PortalWEB/paginas/clientes/clp_grid_citaciones.jsp` | `AppConstants.baseURL` in `Globals.swift` (app target) |
| Query params | `ps_tipo_identificacion=PLA`, `ps_identificacion=<plate>`, `ps_placa=` | Built inside `ANTCarInfoService` |
| Response encoding | ISO Latin 1 | `NetworkConfig.defaultEncoding` |
| Response shape | HTML page with a result table | Parsed by `ANTCarHTMLMapper` |

The `CarHTMLMapper` implementation decodes the response body with `.isoLatin1` at the boundary; downstream layers see UTF-8 `String` only. The base URL must never be referenced from `PlateFinderDomain` — Domain receives a constructed `URL` via constructor injection at the Composition Root.

---

## Domain Models

### `Car`

Pure value type. `Equatable`. No `Codable` in the domain — that extension lives in `Infrastructure/`.

| Property | Type | Source (HTML table cell) |
|---|---|---|
| `plate` | `String` | row 0, cell 0 |
| `manufacturer` | `String` | row 0, cell 2 |
| `colorName` | `String` | row 0, cell 4 |
| `registrationYear` | `String` | row 0, cell 6 |
| `model` | `String` | row 1, cell 1 |
| `segment` | `String` | row 1, cell 3 |
| `registrationDate` | `String` | row 1, cell 5 |
| `year` | `String` | row 2, cell 1 |
| `service` | `String` | row 2, cell 3 |
| `expirationDate` | `String` | row 2, cell 5 |
| `tint` | `String` | row 3, cell 1 |
| `tintExpirationDate` | `String` | row 3, cell 3 |

### `SearchHistoryItem`

```swift
struct SearchHistoryItem: Equatable, Sendable {
    let plateNumber: String
    let searchDate: Date
    let car: Car?          // nil if the search failed
}
```

`Codable` lives in `Infrastructure/SearchHistoryItem+Codable.swift`.

### `PlateFormat`

```swift
enum PlateFormat: Equatable, Sendable {
    case empty
    case partiallyValid
    case invalid
    case bike       // AA123A
    case car        // AAA1234
    case special    // CD1234
}
```

### `CarInfoError`

```swift
enum CarInfoError: Error, Equatable, Sendable {
    case networkError(Error)
    case noDataFound
    case invalidPlateFormat
    case parsingError(String)
    case serverError
}
```

`LocalizedError` conformance lives in the app target.

