# PlateFinder — Module Map & Protocol Contracts

---

## Module Boundaries

### 1. `PlateFinder` — macOS Framework (Domain + Infrastructure protocols)

The domain framework. Targets **macOS only** so all tests run natively without a simulator.

**Allowed imports:** `Foundation`, `Observation`  
**Forbidden imports:** `UIKit`, `SwiftUI`, `AppKit`, `AppIntents`, `SwiftSoup`, `Combine`

Contains:
- Domain models: `Car`, `PlateFormat`, `SearchHistoryItem`, `CarInfoError`
- Domain logic: `PlateValidator`
- Protocol contracts: `HTMLClient`, `CarInfoLoader`, `CarStore`, `FavoritesStore`
- ViewModel: `PlateFinderViewModel` (`@Observable`)

### 2. `PlateFinder` — iOS App Target (Infrastructure + Composition Root)

The app target. Hosts all concrete infrastructure types and the Composition Root.

**Allowed imports:** anything  
**Rule:** No domain model or protocol implementation may import a concrete infrastructure type.

Contains:
- `URLSessionHTTPClient` (conforms to `HTMLClient`)
- `ANTCarInfoService` (conforms to `CarInfoLoader`) — fetches HTML, parses via `CarHTMLMapper`
- `CarHTMLMapper` — static type; maps HTML `Document` → `Car`
- `UserDefaultsCarStore` (conforms to `CarStore` + `FavoritesStore`)
- SwiftUI Views
- Composition Root (`PlateFinderApp.body`)
- `AppIntents` (`FindPlateIntent`, `PlateFinderShortcuts`)

### 3. `PlateFinderTests` — macOS Unit Testing Bundle

Linked against the macOS domain framework. All tests run on Mac — no simulator.

**Uses:** Swift Testing (`import Testing`)

---

## Dependency Direction

```
iOS App Target  ──────────────────────────────────────────────────────────┐
│                                                                          │
│  Composition Root wires:                                                 │
│    URLSessionHTTPClient   ──► HTMLClient (protocol)                      │
│    ANTCarInfoService      ──► CarInfoLoader (protocol)                   │
│    UserDefaultsCarStore   ──► CarStore + FavoritesStore (protocols)      │
│                                                                          │
│  SwiftUI Views bind to:                                                  │
│    PlateFinderViewModel   ◄── @Observable (domain framework)             │
│                                                                          │
└──────────────────────────────────┬───────────────────────────────────────┘
                                   │ depends on (protocols only)
                    ┌──────────────▼──────────────┐
                    │  PlateFinder (macOS Framework)│
                    │                              │
                    │  Car                         │
                    │  PlateFormat                 │
                    │  SearchHistoryItem           │
                    │  CarInfoError                │
                    │  PlateValidator              │
                    │                              │
                    │  HTMLClient        (protocol)│
                    │  CarInfoLoader     (protocol)│
                    │  CarStore          (protocol)│
                    │  FavoritesStore    (protocol)│
                    │                              │
                    │  PlateFinderViewModel        │
                    │   (@Observable)              │
                    └──────────────────────────────┘
```

**Rule:** Arrows never point from the domain framework toward the app target. The app target is the only module that knows about both layers.

---

## Protocol Contracts

All methods use `async throws` (iOS 17+ / Swift 5.5+).

### `HTMLClient`

Abstracts HTTP fetching. The domain framework depends on this; `URLSession` is never mentioned inside the framework.

```swift
protocol HTMLClient {
    func fetchHTML(from url: URL) async throws -> String
}
```

Errors surfaced to callers: `CarInfoError.networkError`, `CarInfoError.serverError`

---

### `CarInfoLoader`

Single use-case protocol. One method, one responsibility.

```swift
protocol CarInfoLoader {
    func loadCarInfo(for plateNumber: String) async throws -> Car
}
```

Success: returns a fully populated `Car`.  
Failure: throws `CarInfoError` (.networkError, .serverError, .noDataFound, .parsingError, .invalidPlateFormat)

---

### `CarStore`

Abstracts search-history persistence. Implementations (UserDefaults, CoreData, in-memory spy) are invisible to the domain.

```swift
protocol CarStore {
    func retrieve() async throws -> [SearchHistoryItem]
    func insert(_ item: SearchHistoryItem) async throws
    func delete(_ item: SearchHistoryItem) async throws
    func deleteAll() async throws
}
```

---

### `FavoritesStore`

Abstracts favorite-plates persistence. Kept separate from `CarStore` (Interface Segregation).

```swift
protocol FavoritesStore {
    func retrieveFavorites() async throws -> [String]
    func insertFavorite(_ plateNumber: String) async throws
    func deleteFavorite(_ plateNumber: String) async throws
}
```

---

## Domain Models

### `Car`

Pure value type. No `Codable` conformance in the domain — that is an infrastructure concern.

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
struct SearchHistoryItem {
    let plateNumber: String
    let searchDate: Date
    let car: Car?          // nil if the search failed
}
```

`Codable` conformance lives in infrastructure (for UserDefaults serialization), not in the domain model.

### `PlateFormat`

```swift
enum PlateFormat: Equatable {
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
enum CarInfoError: Error {
    case networkError(Error)
    case noDataFound
    case invalidPlateFormat
    case parsingError(String)
    case serverError
}
```

`LocalizedError` conformance (user-facing strings) stays in the app target — it is a UI concern.

---

## What Changes from the Current Code

| Current (pre-TDD) | TDD target |
|---|---|
| `CarInfoService` hardcoded in ViewModel | Inject `CarInfoLoader` protocol |
| `URLSession.shared` in `AntScrapper` | `URLSessionHTTPClient` behind `HTMLClient` |
| `isTesting: Bool` flag | Removed — use injected spy in tests |
| `ObservableObject` + `@Published` in ViewModel | `@Observable` (`import Observation`) |
| `Car: Codable` in domain | `Car` is plain struct; `Codable` in infrastructure DTO |
| `UserDataService.shared` singleton | Injected `CarStore` + `FavoritesStore` protocols |
| Localized strings in `CarInfoError` | Move to app target (`LocalizedError` extension) |
| `SwiftUI` imported in ViewModel | Removed — ViewModel has zero UI framework imports |
