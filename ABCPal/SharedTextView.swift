//
//  SharedTextView.swift
//  ABCPal
//
//  Handles text shared into the app via the iOS share sheet.
//  Shows language picker, then displays text and plays TTS.
//

import SwiftUI
import AVFoundation

struct SharedTextView: View {
    let text: String
    let onDismiss: () -> Void

    @StateObject private var vocabManager = VocabularyManager.shared
    @State private var selectedLanguage: String?
    @State private var showingVocabCapture = false

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        if let language = selectedLanguage {
            // Text display and TTS screen
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            synthesizer.stopSpeaking(at: .immediate)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text(language == "fr-CA" ? "Fermer" : language == "ja-JP" ? "閉じる" : "Close")
                            }
                            .padding(8)
                            .foregroundColor(.blue)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    Text(text)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    VStack(spacing: 15) {
                        Button(action: { readTextAloud(language: language) }) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                Text(language == "fr-CA" ? "Lire à haute voix" : language == "ja-JP" ? "読み上げ" : "Read Aloud")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        Button(action: { showingVocabCapture = true }) {
                            HStack {
                                Image(systemName: "text.badge.plus")
                                Text(language == "fr-CA" ? "Capturer le vocabulaire" : language == "ja-JP" ? "語彙をキャプチャ" : "Capture Vocabulary")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        Button(action: {
                            synthesizer.stopSpeaking(at: .immediate)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text(language == "fr-CA" ? "Fermer" : language == "ja-JP" ? "閉じる" : "Close")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemBackground))
            .sheet(isPresented: $showingVocabCapture) {
                VocabCaptureView(
                    text: text,
                    language: language,
                    onComplete: { words in
                        let result = vocabManager.addCustomWords(words, language: language)
                        print("Shared text: added \(result.added) words, skipped \(result.duplicates) duplicates")
                    }
                )
            }
        } else {
            // Language picker
            VStack(spacing: 30) {
                Image(systemName: "text.quote")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text(text)
                    .font(.body)
                    .lineLimit(5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)

                Text("Choose language")
                    .font(.headline)

                HStack(spacing: 16) {
                    Button(action: {
                        selectedLanguage = "en-US"
                        readTextAloud(language: "en-US")
                    }) {
                        VStack {
                            Text("🇺🇸")
                                .font(.system(size: 40))
                            Text("English")
                                .font(.subheadline)
                        }
                        .frame(width: 100, height: 100)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(16)
                    }

                    Button(action: {
                        selectedLanguage = "fr-CA"
                        readTextAloud(language: "fr-CA")
                    }) {
                        VStack {
                            Text("🇫🇷")
                                .font(.system(size: 40))
                            Text("Français")
                                .font(.subheadline)
                        }
                        .frame(width: 100, height: 100)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(16)
                    }

                    Button(action: {
                        selectedLanguage = "ja-JP"
                        readTextAloud(language: "ja-JP")
                    }) {
                        VStack {
                            Text("🇯🇵")
                                .font(.system(size: 40))
                            Text("日本語")
                                .font(.subheadline)
                        }
                        .frame(width: 100, height: 100)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(16)
                    }
                }

                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(.red)
                .padding(.top, 10)
            }
            .padding()
        }
    }

    private func readTextAloud(language: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceForLanguage(language)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
}
