//
//  SettingsView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 09/07/2025.
//

import SwiftUI

struct SettingsView: View {
    @Binding var showLanguageSettings: Bool
    
    var body: some View {
        List {
            Section {
                Button {
                    showLanguageSettings = true
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("language".localized)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            } header: {
                Text("preferences".localized)
            }
        }
        .navigationTitle("settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(showLanguageSettings: .constant(false))
}
