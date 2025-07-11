//
//  LanguageSettingsView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 08/07/2025.
//

import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingLanguageChanged = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppConstants.supportedLanguages, id: \.self) { language in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(AppConstants.languageDisplayName(for: language))
                                    .font(.headline)
                                Text(AppConstants.languageNativeName(for: language))
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
                            showingLanguageChanged = true
                            
                            // Auto-dismiss after a short delay using modern async/await
                            Task {
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                dismiss()
                            }
                        }
                    }
                } header: {
                    Text("select_language".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
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
            .overlay {
                if showingLanguageChanged {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("language_changed".localized)
                                .font(.headline)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showingLanguageChanged)
                }
            }
        }
    }
    
}

#Preview {
    LanguageSettingsView()
        .environmentObject(LanguageManager.shared)
} 
