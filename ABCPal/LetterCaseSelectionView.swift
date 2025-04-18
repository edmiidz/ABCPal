//
//  LetterCaseSelectionView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation

struct LetterCaseSelectionView: View {
    var language: String
    var onCaseSelected: (String) -> Void
    var onBack: () -> Void
    
    @State private var hasSpoken = false
    let synthesizer = AVSpeechSynthesizer()
    
    // Get the user name from UserDefaults
    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }

    var prompt: String {
        language == "fr-CA"
            ? "Veux-tu apprendre les majuscules ou les minuscules, \(userName)?"
            : "Do you want to learn uppercase or lowercase letters, \(userName)?"
    }

    var body: some View {
        VStack(spacing: 30) {
            // Prompt label with TTS
            Button(action: {
                synthesizer.stopSpeaking(at: .immediate)
                speak(text: prompt)
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text(prompt)
                        .font(.title2)
                }
                .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()

            // Uppercase choice with speaker
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onCaseSelected("upper")
                }) {
                    Text(language == "fr-CA" ? "MAJUSCULES" : "UPPERCASE")
                        .font(.title2)
                        .padding()
                        .frame(minWidth: 160)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: language == "fr-CA" ? "Majuscules" : "Uppercase")
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Lowercase choice with speaker
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onCaseSelected("lower")
                }) {
                    Text(language == "fr-CA" ? "minuscules" : "lowercase")
                        .font(.title2)
                        .padding()
                        .frame(minWidth: 160)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: language == "fr-CA" ? "Minuscules" : "Lowercase")
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
                    Text(language == "fr-CA" ? "Retour" : "Back")
                }
                .foregroundColor(.blue)
            }
            .padding(.top, 20)
        }
        .padding()
        .onAppear {
            if !hasSpoken {
                speak(text: prompt)
                hasSpoken = true
            }
        }
    }

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}
