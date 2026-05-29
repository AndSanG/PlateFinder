# PlateFinder — Hard Constraints

## Architecture

- The domain framework targets **macOS only** — all domain, networking, and ViewModel tests run on the Mac without a simulator.
- **No** `UIKit`, `SwiftUI`, `AppKit`, `AppIntents`, or `SwiftSoup` imports inside the domain framework.
- **No** `URLSession` in the domain framework — hide it behind a protocol, inject it.
- **No** `UserDefaults` in the domain framework — persistence is infrastructure.
- HTML parsing stays in the infrastructure layer (app target), not the domain framework.
- The Composition Root (app entry point / `@main App.body`) is the **only** place that creates concrete infrastructure types.

## Concurrency

- All new protocol methods use `async throws` — deployment target is iOS 17+.
- ViewModels use `@Observable` (`import Observation`, not SwiftUI) — not `ObservableObject` / `Combine`.
- `Task` references held for cancellation must be marked `@ObservationIgnored`.

## Testing

- Tests live in a dedicated `PlateFinderTests` target linked against the macOS domain framework.
- Use **Swift Testing** (`import Testing`) everywhere — not XCTest.
- **No `isTesting` flag** in any production type — inject test doubles via protocols instead.
- Memory leak detection required on every test that creates a system under test (SUT): use `weak` + `defer` or `deinit` of the `@Suite` struct.
- One commit per passing test; never batch multiple tests into one commit.

## Encoding

- The ANT endpoint returns ISO Latin 1 — always decode responses with `.isoLatin1`.

## Commit discipline

- Every commit must compile and run — tests may fail (Red), but the build must never be broken.
- Add stubs before committing a failing test.
- Stage files explicitly by name — never `git add .` or `git add -A`.
