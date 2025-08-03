//
//  VocabQuizView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation

struct VocabQuizView: View {
    var language: String
    var goBack: () -> Void

    @State private var correctWord = ""
    @State private var options: [String] = []
    @State private var feedback = ""
    @State private var lastWord: String? = nil
    @State private var isReady = false
    @State private var feedbackOpacity = 1.0
    @State private var hasPlayedPrompt = false
    @State private var areButtonsDisabled = false
    @State private var useLandscapeLayout = true
    @State private var celebrationWord: String? = nil
    @State private var thinkingWord: String? = nil
    @State private var isCompleted = false
    @State private var allWords: [String] = []
    @State private var isFirstAttempt = true
    
    @StateObject private var vocabManager = VocabularyManager.shared
    
    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }
    
    let synthesizer = AVSpeechSynthesizer()
    
    var activeWords: [String] {
        vocabManager.getActiveWords(for: language)
    }
    
    var promptText: String {
        language == "fr-CA"
            ? "Écoute et choisis le bon mot"
            : "Listen and choose the word"
    }

    var body: some View {
        Group {
            if useLandscapeLayout {
                // Landscape layout
                ZStack {
                    if isCompleted {
                        // Celebration view
                        VStack(spacing: 20) {
                            Image("splashImage")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .padding()
                                .transition(.scale)
                            
                            HStack {
                                Text("🎉").font(.system(size: 40))
                                Text("🎊").font(.system(size: 40))
                                Text("🏆").font(.system(size: 40))
                                Text("🎈").font(.system(size: 40))
                            }
                            
                            Text(feedback)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .padding()
                                .animation(.spring(), value: feedbackOpacity)
                        }
                    } else {
                        // Regular quiz view
                        HStack(spacing: 20) {
                            // Left side with prompt and speaker
                            VStack(alignment: .leading, spacing: 30) {
                                if !isCompleted {
                                    Button(action: {
                                        synthesizer.stopSpeaking(at: .immediate)
                                        speak(text: promptText)
                                    }) {
                                        HStack {
                                            Image(systemName: "speaker.wave.2.fill")
                                            Text(promptText)
                                                .font(.title2)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.bottom, 20)
                                    
                                    Button(action: {
                                        synthesizer.stopSpeaking(at: .immediate)
                                        speak(word: correctWord)
                                    }) {
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 40)
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.4)
                            .padding(.leading, 20)
                            
                            if !isCompleted {
                                // Right side with word options
                                VStack(spacing: 20) {
                                    if !options.isEmpty {
                                        ForEach(0..<min(options.count, 4), id: \.self) { index in
                                            Button(action: {
                                                checkAnswer(options[index])
                                            }) {
                                                HStack {
                                                    Text(options[index])
                                                        .font(.title2)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.blue)
                                                    
                                                    if celebrationWord == options[index] {
                                                        Text("🎉")
                                                            .font(.title2)
                                                    }
                                                    if thinkingWord == options[index] {
                                                        Text("🤔")
                                                            .font(.title2)
                                                    }
                                                }
                                                .frame(width: 200, height: 70)
                                                .background(Color.purple.opacity(0.2))
                                                .cornerRadius(20)
                                            }
                                            .disabled(areButtonsDisabled)
                                        }
                                    }
                                }
                                .padding(.trailing, 20)
                            }
                        }
                    }
                    
                    // Back button at top left
                    VStack {
                        HStack {
                            Button(action: {
                                synthesizer.stopSpeaking(at: .immediate)
                                goBack()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.backward")
                                    Text(language == "fr-CA" ? "Retour" : "Back")
                                }
                                .padding(8)
                                .foregroundColor(.blue)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        Spacer()
                    }
                    
                    // Feedback at the bottom
                    if !isCompleted {
                        VStack {
                            Spacer()
                            Text(feedback)
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding()
                                .opacity(feedbackOpacity)
                                .animation(.easeInOut(duration: 0.5), value: feedbackOpacity)
                        }
                    }
                }
            } else {
                // Portrait layout
                ZStack {
                    if isCompleted {
                        VStack(spacing: 20) {
                            HStack {
                                Button(action: {
                                    synthesizer.stopSpeaking(at: .immediate)
                                    goBack()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.backward")
                                        Text(language == "fr-CA" ? "Retour" : "Back")
                                    }
                                    .padding(8)
                                    .foregroundColor(.blue)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                Spacer()
                            }
                            .padding(.top)
                            
                            Spacer()
                            
                            Image("splashImage")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .padding()
                            
                            HStack {
                                Text("🎉").font(.system(size: 40))
                                Text("🎊").font(.system(size: 40))
                                Text("🏆").font(.system(size: 40))
                                Text("🎈").font(.system(size: 40))
                            }
                            
                            Text(feedback)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        VStack(spacing: 30) {
                            HStack {
                                Button(action: {
                                    synthesizer.stopSpeaking(at: .immediate)
                                    goBack()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.backward")
                                        Text(language == "fr-CA" ? "Retour" : "Back")
                                    }
                                    .padding(8)
                                    .foregroundColor(.blue)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                Spacer()
                            }
                            .padding(.top)
                            
                            if !isCompleted {
                                Button(action: {
                                    synthesizer.stopSpeaking(at: .immediate)
                                    speak(text: promptText)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "speaker.wave.2.fill")
                                        Text(promptText)
                                            .font(.title2)
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    synthesizer.stopSpeaking(at: .immediate)
                                    speak(word: correctWord)
                                }) {
                                    Text("🔊")
                                        .font(.system(size: 60))
                                }
                                
                                ForEach(options, id: \.self) { word in
                                    Button(action: {
                                        checkAnswer(word)
                                    }) {
                                        HStack {
                                            Text(word)
                                                .font(.title2)
                                            
                                            if celebrationWord == word {
                                                Text("🎉")
                                                    .font(.title2)
                                            }
                                            if thinkingWord == word {
                                                Text("🤔")
                                                    .font(.title2)
                                            }
                                        }
                                        .frame(minWidth: 150, minHeight: 60)
                                        .background(Color.purple.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    .disabled(areButtonsDisabled)
                                }
                            }
                            
                            Text(feedback)
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding()
                                .opacity(feedbackOpacity)
                                .animation(.easeInOut(duration: 0.5), value: feedbackOpacity)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            loadWords()
            startQuizFlow()
            updateLayoutForCurrentOrientation()
            
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                updateLayoutForCurrentOrientation()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
    
    func loadWords() {
        allWords = language == "en-US" ? vocabManager.englishWords : vocabManager.frenchWords
    }
    
    func updateLayoutForCurrentOrientation() {
        let orientation = UIDevice.current.orientation
        
        if orientation == .portrait {
            self.useLandscapeLayout = false
        } else if orientation == .landscapeLeft || orientation == .landscapeRight {
            self.useLandscapeLayout = true
        }
    }

    func checkAnswer(_ selected: String) {
        areButtonsDisabled = true
        if selected == correctWord {
            // Only increment mastery if this is the first attempt
            if isFirstAttempt {
                let currentMastery = vocabManager.getMastery(for: correctWord, language: language)
                vocabManager.updateMastery(word: correctWord, language: language, count: currentMastery + 1)
                let count = currentMastery + 1

                if count == 1 {
                    celebrationWord = correctWord
                    speak(word: correctWord)
                } else {
                    feedback = language == "fr-CA" ? "Bravo!" : "Good job!"
                    speak(text: feedback)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        speak(word: correctWord)
                    }
                }
            } else {
                // Not first attempt, just acknowledge the correct answer
                celebrationWord = correctWord
                speak(word: correctWord)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                celebrationWord = nil
                startQuizFlow()
            }
        } else {
            thinkingWord = selected
            isFirstAttempt = false  // Mark that first attempt failed
            
            feedback = language == "fr-CA"
                ? "Non, c'est \(selected)."
                : "No, that is \(selected)."
            speak(text: feedback)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    feedbackOpacity = 0.0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                thinkingWord = nil
                feedback = ""
                areButtonsDisabled = false
            }
        }
    }

    func speak(text: String) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }

    func speak(word: String) {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.3
        synthesizer.speak(utterance)
    }

    func startQuizFlow() {
        guard !activeWords.isEmpty else {
            isCompleted = true
            
            feedback = language == "fr-CA"
                ? "Bravo \(userName)! Tu as maîtrisé tous les mots! 🎉🎉"
                : "Good job \(userName)! You've mastered all the words! 🎉🎉"

            correctWord = ""
            options = []
            
            playWhooshSound()
            
            let cleanFeedback = feedback.replacingOccurrences(of: "[\\p{Emoji}]", with: "", options: .regularExpression)
            speak(text: cleanFeedback)
            
            withAnimation(.spring()) {
                feedbackOpacity = 1.0
                celebrationWord = "🎉"
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                goBack()
            }
            
            return
        }
        
        isCompleted = false
        isReady = false

        let availableChoices = activeWords.count == 1
            ? activeWords
            : activeWords.filter { $0 != lastWord }

        correctWord = availableChoices.randomElement() ?? activeWords.first!
        lastWord = correctWord
        
        let distractors = allWords.filter { $0 != correctWord }.shuffled().prefix(3)
        options = Array((distractors + [correctWord]).shuffled())
        feedback = ""
        feedbackOpacity = 1.0
        areButtonsDisabled = false
        isFirstAttempt = true  // Reset for new word

        if !hasPlayedPrompt {
            speak(text: promptText)
            hasPlayedPrompt = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speak(word: correctWord)
                isReady = true
            }
        } else {
            speak(word: correctWord)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isReady = true
            }
        }
    }
}