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
    
    init(language: String, goBack: @escaping () -> Void) {
        self.language = language
        self.goBack = goBack
        print("🎮 VocabQuizView initialized with language: \(language)")
    }

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
    @State private var isAutoPlayMode = false
    @State private var inactivityTimer: Timer? = nil
    @State private var autoPlayTimer: Timer? = nil
    @State private var hasSpelledWord = false
    @State private var isWaitingForNext = false
    @State private var autoPlayDelayTimer: Timer? = nil
    
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
                                                    // Show pointing emoji in autoplay mode for correct answer
                                                    if isAutoPlayMode && options[index].lowercased() == correctWord.lowercased() {
                                                        Text("👈")
                                                            .font(.title2)
                                                    }
                                                }
                                                .frame(width: 200, height: 70)
                                                .background(isWaitingForNext && isAutoPlayMode ? Color.yellow.opacity(0.5) : Color.purple.opacity(0.2))
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
                            
                            // AutoPlay indicator
                            if isAutoPlayMode {
                                HStack(spacing: 5) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.green)
                                    Text("AutoPlay")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .padding(6)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)
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
                                
                                // AutoPlay indicator
                                if isAutoPlayMode {
                                    HStack(spacing: 5) {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.green)
                                        Text("AutoPlay")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding(6)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
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
                                
                                // AutoPlay indicator
                                if isAutoPlayMode {
                                    HStack(spacing: 5) {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.green)
                                        Text("AutoPlay")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding(6)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
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
                                            // Show pointing emoji in autoplay mode for correct answer
                                            if isAutoPlayMode && word.lowercased() == correctWord.lowercased() {
                                                Text("👈")
                                                    .font(.title2)
                                            }
                                        }
                                        .frame(minWidth: 150, minHeight: 60)
                                        .background(isWaitingForNext && isAutoPlayMode ? Color.yellow.opacity(0.5) : Color.purple.opacity(0.2))
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
            print("📱 VocabQuizView appeared")
            loadWords()
            startQuizFlow()
            updateLayoutForCurrentOrientation()
            
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                updateLayoutForCurrentOrientation()
            }
        }
        .onDisappear {
            print("📱 VocabQuizView disappearing")
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
            // Clean up timers
            inactivityTimer?.invalidate()
            autoPlayTimer?.invalidate()
            autoPlayDelayTimer?.invalidate()
        }
    }
    
    func loadWords() {
        allWords = language == "en-US" ? vocabManager.englishWords : vocabManager.frenchWords
        print("📚 VocabQuiz: Loaded \(allWords.count) total words for language: \(language)")
    }
    
    func updateLayoutForCurrentOrientation() {
        // Check if device allows landscape
        guard DeviceHelper.shouldAllowLandscape else {
            // Force portrait layout on small screens
            self.useLandscapeLayout = false
            print("📱 VocabQuizView: Small screen detected, forcing portrait layout")
            return
        }
        
        let orientation = UIDevice.current.orientation
        
        if orientation == .portrait {
            self.useLandscapeLayout = false
        } else if orientation == .landscapeLeft || orientation == .landscapeRight {
            self.useLandscapeLayout = true
        }
    }

    func checkAnswer(_ selected: String) {
        print("✅ VocabQuiz: User selected '\(selected)', correct word is '\(correctWord)'")
        // User interaction - exit autoplay mode and reset timers
        stopAutoPlay()
        resetInactivityTimer()
        
        areButtonsDisabled = true
        // Compare lowercase versions for proper noun support
        if selected.lowercased() == correctWord.lowercased() {
            print("✅ VocabQuiz: Correct answer!")
            // Only increment mastery if this is the first attempt
            if isFirstAttempt {
                let currentMastery = vocabManager.getMastery(for: correctWord, language: language)
                vocabManager.updateMastery(word: correctWord, language: language, count: currentMastery + 1)
                let count = currentMastery + 1

                if count == 1 {
                    celebrationWord = selected  // Use the selected word to maintain display case
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
                celebrationWord = selected  // Use the selected word to maintain display case
                speak(word: correctWord)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                celebrationWord = nil
                startQuizFlow()
            }
        } else {
            print("❌ VocabQuiz: Wrong answer")
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
        print("🔊 VocabQuiz: Speaking text '\(text)'")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }

    func speak(word: String) {
        print("🔊 VocabQuiz: Speaking word '\(word)'")
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.3
        synthesizer.speak(utterance)
    }
    
    func spellWord(_ word: String) {
        // Spell out the word letter by letter with pauses
        let letters = word.map { String($0) }
        
        print("🔤 VocabQuiz: Starting to spell '\(word)' with \(letters.count) letters")
        
        // Speak each letter individually with delays
        for (index, letter) in letters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4) {
                // Continue spelling even if AutoPlay stops (don't check isAutoPlayMode)
                print("🔤 VocabQuiz: Speaking letter '\(letter)' at index \(index)")
                let utterance = AVSpeechUtterance(string: String(letter))
                utterance.voice = AVSpeechSynthesisVoice(language: language)
                utterance.rate = 0.15  // Even slower for spelling (25% slower than before)
                utterance.preUtteranceDelay = 0.04  // 40ms pause before each letter
                synthesizer.speak(utterance)
                
                // Log when this is the last letter
                if index == letters.count - 1 {
                    print("🔤 VocabQuiz: Last letter '\(letter)' queued at \(Date())")
                }
            }
        }
    }

    func startQuizFlow() {
        // Don't stop autoplay if we're already in autoplay mode (continuing to next question)
        let wasInAutoPlay = isAutoPlayMode
        print("🎯 VocabQuiz: startQuizFlow called, wasInAutoPlay = \(wasInAutoPlay)")
        if !wasInAutoPlay {
            stopAutoPlay()
        }
        hasSpelledWord = false
        
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
        } else if !wasInAutoPlay {
            // Only speak the word if we're NOT in AutoPlay (AutoPlay will handle speaking)
            speak(word: correctWord)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isReady = true
            }
        } else {
            // In AutoPlay mode - don't speak here, continueAutoPlay will handle it
            isReady = true
        }
        
        // Handle autoplay or start inactivity timer
        if wasInAutoPlay {
            print("🎯 VocabQuiz: Continuing AutoPlay cycle")
            // Continue autoplay after current word is shown
            continueAutoPlay()
        } else {
            print("🎯 VocabQuiz: Starting 30 second inactivity timer")
            // Start inactivity timer for autoplay
            resetInactivityTimer()
        }
    }
    
    // MARK: - AutoPlay Functions
    
    func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        print("⏰ VocabQuiz: Setting up 30 second inactivity timer")
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            print("⏰ VocabQuiz: Inactivity timer fired! Checking conditions...")
            print("   areButtonsDisabled: \(self.areButtonsDisabled)")
            print("   isCompleted: \(self.isCompleted)")
            print("   isReady: \(self.isReady)")
            print("   options.isEmpty: \(self.options.isEmpty)")
            if !self.areButtonsDisabled && !self.isCompleted && self.isReady && !self.options.isEmpty {
                print("✅ VocabQuiz: All conditions met, starting AutoPlay")
                self.startAutoPlay()
            } else {
                print("❌ VocabQuiz: Conditions not met for AutoPlay")
            }
        }
    }
    
    func startAutoPlay() {
        print("🎯 VocabQuiz AutoPlay: Starting for word '\(correctWord)'")
        print("🔊 VocabQuiz: Current word is: \(correctWord)")
        isAutoPlayMode = true
        hasSpelledWord = false
        
        // Start the autoplay sequence
        continueAutoPlay()
    }
    
    func continueAutoPlay() {
        guard isAutoPlayMode else { 
            print("🎯 VocabQuiz: Not in autoplay mode")
            return 
        }
        guard !isWaitingForNext else { 
            print("🎯 VocabQuiz: Already waiting for next")
            return 
        }
        
        print("🎯 VocabQuiz: AutoPlay cycle for word '\(correctWord)'")
        
        // Cancel any existing timer
        autoPlayDelayTimer?.invalidate()
        
        // Speak the word immediately
        speak(word: correctWord)
        
        // Wait a bit for the word to be spoken, then spell it
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.isAutoPlayMode {
                print("🎯 VocabQuiz: Now spelling '\(self.correctWord)'")
                self.spellWord(self.correctWord)
                
                // Calculate time needed for spelling
                // Each letter dispatch is 0.4s apart, plus time for actual speech
                // With speech rate of 0.15, each letter takes about 0.5-0.7s to speak
                // So we need more buffer time
                let letterSpacing = 0.4 * Double(self.correctWord.count - 1)  // Time between letter dispatches
                let speechBuffer = 1.5  // Extra time for the last letter to finish speaking
                let spellingDuration = letterSpacing + speechBuffer
                print("🎯 VocabQuiz: Spelling will take approximately \(spellingDuration) seconds")
                print("   (Letter spacing: \(letterSpacing)s + Speech buffer: \(speechBuffer)s)")
                
                // Mark as waiting AFTER spelling completes to show visual indicator
                DispatchQueue.main.asyncAfter(deadline: .now() + spellingDuration) {
                    print("🎯 VocabQuiz: Spelling should be complete now")
                    
                    // Check if synthesizer is still speaking
                    if self.synthesizer.isSpeaking {
                        print("⚠️ VocabQuiz: Synthesizer is still speaking! Waiting a bit more...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.startSilentPause()
                        }
                    } else {
                        self.startSilentPause()
                    }
                }
            }
        }
    }
    
    func startSilentPause() {
        self.isWaitingForNext = true  // Show yellow buttons during pause
        print("🟡 VocabQuiz: Buttons should now be YELLOW for 5-second pause")
        print("⏱️ VocabQuiz: Starting 5-second SILENT pause at \(Date())")
        print("🔇 VocabQuiz: NO AUDIO should play for the next 5 seconds")
        
        // Use a Timer for the actual 5-second SILENT delay
        self.autoPlayDelayTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            print("⏱️ VocabQuiz: 5-second pause complete at \(Date())")
            print("🟢 VocabQuiz: Moving to next word now")
            self.isWaitingForNext = false
            if self.isAutoPlayMode {
                self.startQuizFlow()
            }
        }
    }
    
    func stopAutoPlay() {
        print("🛑 VocabQuiz: Stopping AutoPlay")
        isAutoPlayMode = false
        isWaitingForNext = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
        autoPlayDelayTimer?.invalidate()
        autoPlayDelayTimer = nil
    }
}