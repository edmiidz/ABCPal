//
//  SharedImageCaptureView.swift
//  ABCPal
//
//  Handles images shared into the app via the iOS share sheet.
//  If the user has previously selected a language in the app,
//  auto-starts OCR with that language. Otherwise shows a picker.
//

import SwiftUI
import AVFoundation

struct SharedImageCaptureView: View {
    let image: UIImage
    let onDismiss: () -> Void

    @State private var selectedLanguage: String?
    @State private var hasAutoStarted = false

    var body: some View {
        if let language = selectedLanguage {
            ImageReaderView(
                image: image,
                language: language,
                onDismiss: onDismiss
            )
        } else {
            // Language picker (only shown if no saved language)
            VStack(spacing: 30) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .padding(.horizontal)

                Text("Choose language")
                    .font(.headline)

                HStack(spacing: 16) {
                    languageButton(flag: "🇺🇸", name: "English", code: "en-US")
                    languageButton(flag: "🇫🇷", name: "Français", code: "fr-CA")
                    languageButton(flag: "🇯🇵", name: "日本語", code: "ja-JP")
                }

                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(.red)
                .padding(.top, 10)
            }
            .padding()
            .onAppear {
                // Auto-use saved language if available
                if !hasAutoStarted,
                   let saved = UserDefaults.standard.string(forKey: "selectedLanguage"),
                   ["en-US", "fr-CA", "ja-JP"].contains(saved) {
                    hasAutoStarted = true
                    selectedLanguage = saved
                }
            }
        }
    }

    private func languageButton(flag: String, name: String, code: String) -> some View {
        Button(action: { selectedLanguage = code }) {
            VStack {
                Text(flag)
                    .font(.system(size: 40))
                Text(name)
                    .font(.subheadline)
            }
            .frame(width: 100, height: 100)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(16)
        }
    }
}
