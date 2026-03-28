//
//  VocabModeSelectionView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 3/12/26.
//

import SwiftUI
import AVFoundation

struct VocabModeSelectionView: View {
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
        case "fr-CA": return "Comment veux-tu pratiquer, \(userName)?"
        case "ja-JP": return "どう練習したい、\(userName)？"
        default: return "How do you want to practice, \(userName)?"
        }
    }

    var chooseWordText: String {
        switch language {
        case "fr-CA": return "Choisis le mot"
        case "ja-JP": return "言葉を選ぶ"
        default: return "Choose the Word"
        }
    }

    var chooseSoundText: String {
        switch language {
        case "fr-CA": return "Choisis le son"
        case "ja-JP": return "音を選ぶ"
        default: return "Choose the Sound"
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

            // Choose the Word option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onModeSelected("vocab_word")
                }) {
                    HStack {
                        Image(systemName: "textformat")
                        Text(chooseWordText)
                    }
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 250)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: chooseWordText)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Choose the Sound option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onModeSelected("vocab_sound")
                }) {
                    HStack {
                        Image(systemName: "ear")
                        Text(chooseSoundText)
                    }
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 250)
                    .background(Color.teal.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: chooseSoundText)
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
