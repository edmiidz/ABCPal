//
//  QuizView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation

struct QuizView: View {
    var language: String
    var letterCase: String
    var goBack: () -> Void

    @State private var correctLetter = ""
    @State private var options: [String] = []
    @State private var feedback = ""
    @State private var mastery: [String: Int] = [:]
    @State private var lastLetter: String? = nil
    @State private var isReady = false
    @State private var feedbackOpacity = 1.0
    @State private var hasPlayedPrompt = false
    @State private var areButtonsDisabled = false
    @State private var useLandscapeLayout = true
    
    // Get the user name from UserDefaults
    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }
    
    let synthesizer = AVSpeechSynthesizer()
    var allLetters: [String] {
        let base = (65...90).map { String(UnicodeScalar($0)!) }
        return letterCase == "lower" ? base.map { $0.lowercased() } : base
    }
    
    var activeLetters: [String] {
        allLetters.filter { (mastery[$0] ?? 0) < 2 }
    }
    
    var promptText: String {
        language == "fr-CA"
            ? "Écoute et choisis la bonne lettre"
            : "Listen and choose the letter"
    }

    var body: some View {
        Group {
            if useLandscapeLayout {
                // Landscape layout as default
                ZStack {
                    // Main content area
                    HStack(spacing: 20) {
                        // Left side with prompt and speaker
                        VStack(alignment: .leading, spacing: 30) {
                            // Prompt with speaker icon
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
                            
                            // Speaker button
                            Button(action: {
                                synthesizer.stopSpeaking(at: .immediate)
                                speak(letter: correctLetter)
                            }) {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 40)
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.4)
                        .padding(.leading, 20)
                        
                        // Right side with letter options
                        VStack(spacing: 20) {
                            if !options.isEmpty {
                                ForEach(0..<min(options.count, 4), id: \.self) { index in
                                    Button(action: {
                                        checkAnswer(options[index])
                                    }) {
                                        Text(options[index])
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                            .frame(width: 180, height: 70)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(20)
                                    }
                                    .disabled(areButtonsDisabled)
                                }
                            }
                        }
                        .padding(.trailing, 20)
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
            } else {
                // Portrait layout - only used when definitively in portrait
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
                        speak(letter: correctLetter)
                    }) {
                        Text("🔊")
                            .font(.system(size: 60))
                    }
                    
                    ForEach(options, id: \.self) { letter in
                        Button(action: {
                            checkAnswer(letter)
                        }) {
                            Text(letter)
                                .font(.largeTitle)
                                .frame(minWidth: 150, minHeight: 60)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                        }
                        .disabled(areButtonsDisabled)
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
        .onAppear {
            startQuizFlow()
            
            // Start with landscape layout by default
            updateLayoutForCurrentOrientation()
            
            // Set up orientation notification with more stable detection
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                updateLayoutForCurrentOrientation()
            }
        }
        .onDisappear {
            // Remove observer when view disappears
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
    
    func updateLayoutForCurrentOrientation() {
        // More robust orientation detection - only switch to portrait if truly portrait
        let orientation = UIDevice.current.orientation
        
        if orientation == .portrait {
            // Only use portrait layout for definitive portrait orientation
            self.useLandscapeLayout = false
        } else if orientation == .landscapeLeft || orientation == .landscapeRight {
            // Use landscape layout for definitive landscape orientations
            self.useLandscapeLayout = true
        }
        // For other cases like faceUp, faceDown, or unknown, keep the current layout
    }

    func checkAnswer(_ selected: String) {
        areButtonsDisabled = true
        if selected == correctLetter {
            mastery[correctLetter, default: 0] += 1
            let count = mastery[correctLetter] ?? 0

            if count == 1 {
                feedback = language == "fr-CA"
                    ? "C'est \(correctLetter.uppercased())."
                    : "That's right, it was \(correctLetter.uppercased())."
            } else {
                feedback = language == "fr-CA"
                    ? "Bravo!"
                    : "Good job!"
                speak(text: feedback)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startQuizFlow()
            }
        } else {
            feedback = language == "fr-CA"
                ? "Non, c'est \(selected.uppercased())."
                : "No, that is \(selected.uppercased())."
            speak(text: feedback)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    feedbackOpacity = 0.0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

    func speak(letter: String) {
        let utterance = AVSpeechUtterance(string: letter.lowercased())
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.24  // 60% of the regular 0.4 rate
        synthesizer.speak(utterance)
    }

    func startQuizFlow() {
        guard !activeLetters.isEmpty else {
            feedback = language == "fr-CA"
                ? "\(userName), ouah ! Tu as maîtrisé toutes les lettres !"
                : "\(userName), wow! You've mastered all the letters!"

            correctLetter = ""
            options = []
            speak(text: feedback)
            return
        }

        isReady = false

        // Filter out the last used letter unless it's the only one left
        let availableChoices = activeLetters.count == 1
            ? activeLetters
            : activeLetters.filter { $0 != lastLetter }

        correctLetter = availableChoices.randomElement() ?? activeLetters.first!
        lastLetter = correctLetter
        
        let distractors = allLetters.filter { $0 != correctLetter }.shuffled().prefix(3)
        options = Array((distractors + [correctLetter]).shuffled())
        feedback = ""
        feedbackOpacity = 1.0
        areButtonsDisabled = false

        // Speak prompt only if it's the first time
        if !hasPlayedPrompt {
            speak(text: promptText)
            hasPlayedPrompt = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speak(letter: correctLetter)
                isReady = true
            }
        } else {
            speak(letter: correctLetter)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isReady = true
            }
        }
    }
}
