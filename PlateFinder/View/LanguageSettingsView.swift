//
//  LanguageSettingsView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 08/07/2025.
//

import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppConstants.supportedLanguages, id: \.self) { language in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(languageDisplayName(for: language))
                                    .font(.headline)
                                Text(languageNativeName(for: language))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            languageManager.setLanguage(language)
                            dismiss()
                        }
                    }
                } header: {
                    Text("select_language".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                } footer: {
                    Text("app_restart_notice".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func languageDisplayName(for language: String) -> String {
        switch language {
        case "en":
            return "English"
        case "es":
            return "Spanish"
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
        default:
            return language.uppercased()
        }
    }
}

#Preview {
    LanguageSettingsView()
} 