# PlateFinder Localization Guide

This document explains how localization is implemented in the PlateFinder app and how to add new languages.

## Current Supported Languages

- **Spanish (es)** - Default language
- **English (en)** - Secondary language

## File Structure

```
PlateFinder/Resources/
├── en.lproj/
│   └── Localizable.strings    # English translations
├── es.lproj/
│   └── Localizable.strings    # Spanish translations
└── README_Localization.md     # This file
```

## How Localization Works

### 1. String Extension
The app uses a custom `String` extension in `Globals.swift`:

```swift
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
```

### 2. Usage in Code
Instead of hardcoded strings, use the `.localized` property:

```swift
// Before
Text("Enter Plate")

// After
Text("enter_plate".localized)
```

### 3. Localization Files
Each language has its own `Localizable.strings` file with key-value pairs:

```strings
"enter_plate" = "Enter Plate";
"search" = "Search";
```

## Adding a New Language

### Step 1: Create Language Directory
Create a new directory for your language code (e.g., `fr.lproj` for French):

```bash
mkdir -p PlateFinder/Resources/fr.lproj
```

### Step 2: Create Localizable.strings File
Copy the English file and translate all values:

```bash
cp PlateFinder/Resources/en.lproj/Localizable.strings PlateFinder/Resources/fr.lproj/
```

### Step 3: Update AppConstants
Add the new language to the supported languages list in `Globals.swift`:

```swift
static let supportedLanguages = ["en", "es", "fr"]
```

### Step 4: Update Info.plist
Add the language code to the `CFBundleLocalizations` array in `Info.plist`:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>es</string>
    <string>fr</string>
</array>
```

### Step 5: Add Language Names
Update the `LanguageSettingsView.swift` to include display names for the new language:

```swift
private func languageDisplayName(for language: String) -> String {
    switch language {
    case "en":
        return "English"
    case "es":
        return "Spanish"
    case "fr":
        return "French"
    default:
        return language.uppercased()
    }
}

private func languageNativeName(for language: String) -> String {
    switch language {
    case "en":
        return "English"
    case "es":
        return "Español"
    case "fr":
        return "Français"
    default:
        return language.uppercased()
    }
}
```

## Language Keys Reference

### Navigation & Tabs
- `search` - Search tab
- `history` - History tab
- `favorites` - Favorites tab
- `settings` - Settings tab
- `history_and_favorites` - History & Favorites title

### Plate Search
- `enter_plate` - Enter plate input label
- `consult` - Consult button
- `return` - Return button
- `search_title` - Search navigation title

### Info Banner
- `important` - Important banner title
- `enter_plate_without_dash` - Plate format instruction

### Loading
- `searching_information` - Searching information message
- `consulting_ant_database` - Database consultation message
- `loading` - Generic loading message
- `processing_data` - Data processing message

### History & Favorites
- `no_search_history` - Empty history message
- `recent_searches_will_appear_here` - History explanation
- `no_favorite_plates` - Empty favorites message
- `mark_plates_as_favorites_for_quick_access` - Favorites explanation
- `clear` - Clear button
- `clear_history` - Clear history title
- `clear_history_confirmation` - Clear history confirmation
- `cancel` - Cancel button

### Car Details
- `year` - Year label
- `color` - Color label
- `usage` - Usage label
- `registration` - Registration label
- `registration_validity` - Registration validity label
- `tint_validity` - Tint validity label
- `no_information` - No information message

### Actions
- `delete` - Delete action
- `remove` - Remove action

### Errors
- `network_error` - Network error message
- `no_data_found` - No data found message
- `invalid_plate_format` - Invalid format message
- `parsing_error` - Parsing error message
- `server_error` - Server error message

### Error Recovery Suggestions
- `check_internet_connection` - Internet connection suggestion
- `ensure_plate_registered` - Plate registration suggestion
- `use_correct_format` - Format suggestion
- `try_again_later` - Retry suggestion

### Settings
- `language` - Language setting
- `preferences` - Preferences section

## Testing Localization

### Simulator Testing
1. Open the app in the iOS Simulator
2. Go to Settings > General > Language & Region
3. Add your language and set it as primary
4. Restart the app

### Device Testing
1. Install the app on a device
2. Go to Settings > General > Language & Region
3. Add your language and set it as primary
4. Restart the app

### In-App Language Switching
1. Open the app
2. Go to the Settings tab
3. Tap on Language
4. Select your desired language
5. The app will restart with the new language

## Best Practices

1. **Always use localization keys** - Never hardcode strings in the UI
2. **Use descriptive keys** - Make keys self-documenting
3. **Group related keys** - Use consistent naming patterns
4. **Test thoroughly** - Verify all strings appear correctly
5. **Consider context** - Some strings may need different translations based on context
6. **Keep translations up to date** - Update all language files when adding new features

## Troubleshooting

### Strings Not Appearing
- Check that the key exists in all language files
- Verify the key spelling matches exactly
- Ensure the `.localized` property is being used

### Language Not Switching
- Check that the language code is added to `supportedLanguages`
- Verify the language is listed in `Info.plist`
- Ensure the language directory exists with the correct name

### Missing Translations
- Add the missing key to all language files
- Use the English version as a fallback
- Consider using a translation service for accuracy 