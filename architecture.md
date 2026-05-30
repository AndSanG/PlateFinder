# PlateFinder — Architecture Rules

High-level rules. For concrete modules, types, protocol contracts, and the project's current refactor backlog, see [ModuleMap.md](ModuleMap.md).

## Layers

Clean Architecture with three layers. Dependencies point inward only: Presentation → Domain ← Data. Domain knows nothing of the other two.

### Domain Layer

Pure business logic. Contains:
- **Entities** — value types (`struct`/`enum`), `Equatable`, no `Codable`
- **Use Case protocols** — single-method `async throws` interfaces; one protocol = one business action
- **Repository protocols** — abstractions over persistence/networking
- **Domain logic** — pure functions and value types
- **Presentation state** — per-screen `ViewState` enums and the `@Observable` ViewModels that own them

Strict Clean Architecture would put ViewModels in Presentation. We keep them in Domain on purpose: the framework targets macOS, so Domain + Use Case + ViewModel tests run natively at `swift test` speed with no iOS Simulator boot. The trade-off is enforced by the import list below — a ViewModel that needs `SwiftUI`/`UIKit` doesn't compile, which keeps presentation concerns from leaking in.

**Allowed imports:** `Foundation`, `Observation`
**Forbidden imports (Domain only):** `UIKit`, `SwiftUI`, `AppKit`, `AppIntents`, `Combine`, `CoreData`, `SwiftData`, `Security`, any networking or HTML-parsing library
**Forbidden APIs (Domain only):** `URLSession`, `UserDefaults`, `FileManager` paths, `NotificationCenter` for cross-layer events
**ViewModels in Domain use `@Observable` from `Observation` only** — never SwiftUI's `@Bindable`, `@State`, `@Binding`, `@FocusState`, etc. Those wrappers belong to Views.

### Data Layer

Implements domain Repository protocols and concrete Use Cases. Contains:
- API clients behind domain protocols
- Gateways / Services — one per external system
- DTOs — wire/persistence formats; never leak to Domain
- Mappers — translate DTO → Entity at the layer boundary; failures throw domain errors
- Persistence adapters behind domain protocols
- `Codable` conformances for Entities (infrastructure-only extensions)

### Presentation Layer

**SwiftUI is the only UI framework.** No `UIKit` views, view controllers, `UIAlertController`, `UIApplication`, or scene-walking.

MVVM with SwiftUI + `@Observable`. Contains:
- **ViewModels** — `@Observable @MainActor final class`; expose a single `public private(set) var state: ViewState`; depend on **Use Case protocols only** — never repositories or concrete types
- **Views** — pure SwiftUI (`struct: View`); passive; render via exhaustive `switch viewModel.state`; mutate only via ViewModel intent methods; confirmations use `.alert(...)`
- **Routers** — `@Observable @MainActor` types in the domain layer, injected via SwiftUI `.environment(...)`; `AppRouter` owns a `Tab` enum (no `NavigationPath` — domain forbids SwiftUI import); `IntentRouter` bridges AppIntents to the SwiftUI tree
- **State wrappers** — `@State`, `@Bindable`, `@Environment(Type.self)`; never `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject`

## State-Driven MVVM

Every screen is a finite state machine. Invalid UI states must be compiler-impossible.

- Every screen has a single `ViewState` enum with payload-bearing cases (typical: `.idle`, `.loading`, `.success(Data)`, `.error(message)`)
- Multiple booleans on a ViewModel (`isLoading`, `hasError`, `isRefreshing`, …) are **prohibited** — express them as enum cases
- User intents are distinct ViewModel methods, not `Bool` toggles set from Views
- The View body branches on `switch viewModel.state` with an explicit case per value; no `default:` unless conceptually required
- No business logic, formatting, or data mutation inside the View

## Composition Root

The `@main App.body` is the **only** place that constructs concrete adapters and Use Case implementations and wires them into ViewModels via constructor injection.

## Dependency Injection

- Constructor injection or SwiftUI `@Environment(...)` only
- **No singletons** — no `static let shared`, no global `UserDefaults.standard` reads outside the Composition Root
- **No `isTesting` flag** in production types — inject test doubles via protocols

## Concurrency

- All protocol methods are `async throws` — deployment targets iOS 17+ and macOS 15+ (`PlateFinderDomain` framework)
- ViewModels: `@Observable @MainActor final class` (`import Observation`, not SwiftUI / Combine)
- `Task` references held for cancellation are `@ObservationIgnored`
- Types crossing actor boundaries are `Sendable`
- Shared Data Layer adapters are `actor` or `Sendable` final classes

## Testing

- Swift Testing (`import Testing`) everywhere; never XCTest
- Each layer has its own test bundle; a layer's test bundle links only against the modules it owns
- Memory-leak detection on every SUT: `weak` + `defer` or `deinit` of the `@Suite` struct
- One commit per passing test; never batch

## Encoding

- External endpoints document their encoding; decode at the boundary, not later

## Commit discipline

- Every commit must compile — tests may fail (Red), but the build must never be broken
- Add stubs before committing a failing test
- Stage files explicitly by name — never `git add .` or `git add -A`
