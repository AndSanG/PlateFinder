# PlateFinder

![Unit Tests](https://github.com/AndSanG/PlateFinder/actions/workflows/ci.yml/badge.svg)

An iOS app to look up plate information.

## Features

- Search car info by license plate number
- Supports all standard Ecuadorian plate formats
- Siri Shortcuts integration for hands-free searches
- Real-time plate format feedback as you type

## Plate Number Validation

PlateFinder recognizes three types of Ecuadorian license plates:

**Regular cars** — the most common format. Three letters followed by four numbers, like `ABC1234`.

**Motorcycles** — two letters, three numbers, and one letter at the end, like `AB123A`. The trailing letter is what sets them apart from other formats.

**Special plates** — used by diplomatic missions, government vehicles, and similar cases. Two letters followed by four numbers, like `CD1234`. They look similar to a car plate but are one letter shorter.

While typing, the app accepts any input that could still lead to a valid plate — so you can type freely without being interrupted mid-entry. The moment the plate is complete and matches one of the formats above, the search button activates. Anything that clearly doesn't fit any of the three formats is rejected right away.

## Requirements

- iOS 17+
- Xcode 26+

## Building

Open `PlateFinder.xcodeproj` in Xcode and run on a simulator or device.

For beta distribution via TestFlight, the project uses Fastlane. See the `fastlane/` directory for available lanes.

## CI/CD

The project follows GitHub Flow. All changes go through a feature branch and a PR into `master`.

| Trigger          | What happens                              |
| ---------------- | ----------------------------------------- |
| PR → `master`    | Unit tests + build check                  |
| Merge → `master` | Unit tests + fresh build + TestFlight ⚠️  |
| Push tag `v*`    | Unit tests + build + App Store submission |
| Manual dispatch  | Choose `beta` or `release` lane           |

> ⚠️ The merge to `master` triggers a fresh build instead of reusing the one from the PR check — a GitHub Actions limitation. A future improvement would upload the `.ipa` as an artifact on the PR run and download it on merge to skip re-archiving.

To ship a release, tag the commit on `master`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Secrets required in the repository: `MATCH_PASSWORD`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY`, and `MATCH_GIT_BASIC_AUTHORIZATION` (release only).

### Branch flow

```
master  ──●────────────────●────────────────●──────────●─── ...
           \              /                  \         /│
feat/A      ●──●──●──────●        feat/B     ●──●──●──● │
                                                        │
                                                      tag v1.0.0
                                                    (→ App Store)
```

Every merge to `master` uploads to TestFlight. Tags trigger the App Store submission.

### Example: shipping a feature

```bash
# 1. Start from master
git checkout master
git pull origin master

# 2. Create a feature branch
git checkout -b feat/my-feature

# 3. Work, commit, repeat
git add ...
git commit -m "feat: my feature"

# 4. Open a PR → build check runs automatically
git push origin feat/my-feature
gh pr create --base master

# 5. Merge PR → TestFlight upload triggers automatically.

# 6. When ready for App Store, tag master
git checkout master
git pull origin master
git tag v1.2.0
git push origin v1.2.0
```
