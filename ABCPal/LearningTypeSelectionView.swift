//
//  LearningTypeSelectionView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct LearningTypeSelectionView: View {
    var language: String
    var onTypeSelected: (String) -> Void
    var onBack: () -> Void
    /// Called when user picks a photo directly from this menu
    var onPhotoPicked: ((UIImage) -> Void)?

    @State private var hasSpoken = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    let synthesizer = AVSpeechSynthesizer()
    @StateObject private var vocabManager = VocabularyManager.shared
    
    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }

    var prompt: String {
        switch language {
        case "fr-CA": return "Que veux-tu apprendre aujourd'hui, \(userName)?"
        case "ja-JP": return "今日は何を学びたいですか、\(userName)？"
        default: return "What do you want to learn today, \(userName)?"
        }
    }

    var abcUpperText: String {
        language == "fr-CA" ? "ABC MAJUSCULES" : "ABC UPPERCASE"
    }

    var abcLowerText: String {
        language == "fr-CA" ? "abc minuscules" : "abc lowercase"
    }

    var vocabText: String {
        switch language {
        case "fr-CA": return "Vocabulaire"
        case "ja-JP": return "語彙"
        default: return "Vocabulary"
        }
    }

    var readBookText: String {
        switch language {
        case "fr-CA": return "Lire un livre"
        case "ja-JP": return "本を読む"
        default: return "Read a Book"
        }
    }

    var pickPhotoText: String {
        switch language {
        case "fr-CA": return "Choisir une photo"
        case "ja-JP": return "写真を選ぶ"
        default: return "Pick a Photo"
        }
    }

    var numbersText: String {
        switch language {
        case "fr-CA": return "Nombres 1-100"
        case "ja-JP": return "数字 1-100"
        default: return "Numbers 1-100"
        }
    }

    var isJapanese: Bool {
        language == "ja-JP"
    }

    var hasVocabulary: Bool {
        let words = vocabManager.wordsForLanguage(language)
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

            // ABC options - hidden for Japanese (no Latin alphabet)
            if !isJapanese {
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
            
            // Pick a Photo option (quick OCR from photo library)
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(pickPhotoText)
                    }
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.teal.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speak(text: pickPhotoText)
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
                    Text(language == "fr-CA" ? "Retour" : language == "ja-JP" ? "戻る" : "Back")
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
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem = newItem else { return }
            newItem.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    selectedPhotoItem = nil
                    if case .success(let data) = result,
                       let data = data,
                       let uiImage = UIImage(data: data) {
                        let fixed = fixImageOrientation(uiImage)
                        onPhotoPicked?(fixed)
                    }
                }
            }
        }
    }

    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalized
    }

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceForLanguage(language)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}