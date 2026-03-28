//
//  NumbersModeSelectionView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 3/13/26.
//

import SwiftUI
import AVFoundation

struct NumbersModeSelectionView: View {
    var language: String
    var onModeSelected: (String) -> Void
    var onBack: () -> Void

    let synthesizer = AVSpeechSynthesizer()
    @State private var hasSpoken = false

    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }

    var promptText: String {
        switch language {
        case "fr-CA": return "Comment veux-tu pratiquer les nombres, \(userName)?"
        case "ja-JP": return "数字をどう練習したい、\(userName)？"
        default: return "How do you want to practice numbers, \(userName)?"
        }
    }

    var findNumberText: String {
        switch language {
        case "fr-CA": return "Trouve le nombre"
        case "ja-JP": return "数字を見つける"
        default: return "Find the Number"
        }
    }

    var sayNumberText: String {
        switch language {
        case "fr-CA": return "Dis le nombre"
        case "ja-JP": return "数字を言う"
        default: return "Say the Number"
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            // Prompt with speaker
            Button(action: {
                synthesizer.stopSpeaking(at: .immediate)
                speak(text: promptText)
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text(promptText)
                        .font(.title2)
                }
                .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()

            // Find the Number option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onModeSelected("numbers_find")
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text(findNumberText)
                    }
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 250)
                    .background(Color.indigo.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: findNumberText)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Say the Number option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onModeSelected("numbers_say")
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text(sayNumberText)
                    }
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 250)
                    .background(Color.cyan.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: sayNumberText)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Back button
            Button(action: {
                synthesizer.stopSpeaking(at: .immediate)
                onBack()
            }) {
                HStack {
                    Image(systemName: "arrow.backward")
                    Text(language == "fr-CA" ? "Retour" : language == "ja-JP" ? "戻る" : "Back")
                }
                .foregroundColor(.blue)
            }
            .padding(.top, 20)
        }
        .padding()
        .onAppear {
            if !hasSpoken {
                speak(text: promptText)
                hasSpoken = true
            }
        }
    }

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceForLanguage(language)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}
