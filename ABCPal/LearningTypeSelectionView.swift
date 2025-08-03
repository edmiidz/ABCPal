//
//  LearningTypeSelectionView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation

struct LearningTypeSelectionView: View {
    var language: String
    var onTypeSelected: (String) -> Void
    var onBack: () -> Void
    
    @State private var hasSpoken = false
    let synthesizer = AVSpeechSynthesizer()
    @StateObject private var vocabManager = VocabularyManager.shared
    
    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }

    var prompt: String {
        language == "fr-CA"
            ? "Que veux-tu apprendre aujourd'hui, \(userName)?"
            : "What do you want to learn today, \(userName)?"
    }
    
    var abcUpperText: String {
        language == "fr-CA" ? "ABC MAJUSCULES" : "ABC UPPERCASE"
    }
    
    var abcLowerText: String {
        language == "fr-CA" ? "abc minuscules" : "abc lowercase"
    }
    
    var vocabText: String {
        language == "fr-CA" ? "Vocabulaire" : "Vocabulary"
    }
    
    var readBookText: String {
        language == "fr-CA" ? "Lire un livre" : "Read a Book"
    }
    
    var numbersText: String {
        language == "fr-CA" ? "Nombres 1-100" : "Numbers 1-100"
    }
    
    var hasVocabulary: Bool {
        let words = language == "en-US" ? vocabManager.englishWords : vocabManager.frenchWords
        return !words.isEmpty
    }

    var body: some View {
        VStack(spacing: 30) {
            // Prompt with speaker
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

            // ABC Uppercase option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onTypeSelected("abc_upper")
                }) {
                    Text(abcUpperText)
                        .font(.title2)
                        .padding()
                        .frame(minWidth: 200)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: abcUpperText)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // ABC Lowercase option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onTypeSelected("abc_lower")
                }) {
                    Text(abcLowerText)
                        .font(.title2)
                        .padding()
                        .frame(minWidth: 200)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: abcLowerText)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Vocabulary option - only show if vocabulary exists
            if hasVocabulary {
                HStack(spacing: 12) {
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        onTypeSelected("vocab")
                    }) {
                        Text(vocabText)
                            .font(.title2)
                            .padding()
                            .frame(minWidth: 200)
                            .background(Color.purple.opacity(0.3))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        speak(text: vocabText)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Read a Book option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onTypeSelected("read_book")
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text(readBookText)
                    }
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: readBookText)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Numbers option
            HStack(spacing: 12) {
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    onTypeSelected("numbers")
                }) {
                    HStack {
                        Text("🔢")
                        Text(numbersText)
                    }
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.indigo.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: numbersText)
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