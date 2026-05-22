# PlateFinder

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
- Xcode 16+

## Building

Open `PlateFinder.xcodeproj` in Xcode and run on a simulator or device.

For beta distribution via TestFlight, the project uses Fastlane. See the `fastlane/` directory for available lanes.
