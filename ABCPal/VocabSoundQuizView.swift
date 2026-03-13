//
//  VocabSoundQuizView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 3/12/26.
//

import SwiftUI
import AVFoundation

struct VocabSoundQuizView: View {
    var language: String
    var goBack: () -> Void

    init(language: String, goBack: @escaping () -> Void) {
        self.language = language
        self.goBack = goBack
        print("🎧 VocabSoundQuizView initialized with language: \(language)")
    }

    @State private var correctWord = ""
    @State private var options: [String] = []
    @State private var selectedOption: String? = nil
    @State private var feedback = ""
    @State private var lastWord: String? = nil
    @State private var isReady = false
    @State private var feedbackOpacity = 1.0
    @State private var hasPlayedPrompt = false
    @State private var areButtonsDisabled = false
    @State private var useLandscapeLayout = true
    @State private var celebrationIndex: Int? = nil
    @State private var thinkingIndex: Int? = nil
    @State private var revealedWord: String? = nil
    @State private var isCompleted = false
    @State private var allWords: [String] = []
    @State private var isFirstAttempt = true
    @State private var currentWordSet: [String] = []
    @State private var remainingWords: [String] = []
    @State private var isShowingContinuePrompt = false
    @State private var masteredInCurrentSet = 0
    @State private var totalInCurrentSet = 0
    @State private var isQuizzingAllWords = false

    @StateObject private var vocabManager = VocabularyManager.shared

    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }

    let synthesizer = AVSpeechSynthesizer()

    var activeWords: [String] {
        if !currentWordSet.isEmpty {
            return currentWordSet.filter { vocabManager.getMastery(for: $0, language: language) < 2 }
        }
        return vocabManager.getActiveWords(for: language)
    }

    var promptText: String {
        language == "fr-CA"
            ? "Lis le mot et choisis le bon son"
            : "Read the word and choose the right sound"
    }

    var body: some View {
        Group {
            if useLandscapeLayout {
                landscapeBody
            } else {
                portraitBody
            }
        }
        .onAppear {
            print("📱 VocabSoundQuizView appeared")
            loadWords()
            setupInitialWordSet()
            startQuizFlow()
            updateLayoutForCurrentOrientation()

            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                updateLayoutForCurrentOrientation()
            }
        }
        .onDisappear {
            print("📱 VocabSoundQuizView disappearing")
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - Landscape Layout

    var landscapeBody: some View {
        ZStack {
            if isCompleted {
                completionView
            } else {
                HStack(spacing: 20) {
                    // Left side: prompt and the word to identify
                    VStack(alignment: .leading, spacing: 30) {
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

                        // Display the word as text
                        Text(correctWord)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.leading, 40)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.4)
                    .padding(.leading, 20)

                    // Right side: 4 sound options with checkboxes
                    VStack(spacing: 16) {
                        if !options.isEmpty {
                            ForEach(0..<min(options.count, 4), id: \.self) { index in
                                soundOptionRow(index: index, isLandscape: true)
                            }
                        }
                    }
                    .padding(.trailing, 20)
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

            // Feedback and progress at bottom
            if !isCompleted {
                VStack {
                    Spacer()

                    if !currentWordSet.isEmpty && !isShowingContinuePrompt {
                        progressBar
                    }

                    Text(feedback)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                        .opacity(feedbackOpacity)
                        .animation(.easeInOut(duration: 0.5), value: feedbackOpacity)
                }
            }
        }
    }

    // MARK: - Portrait Layout

    var portraitBody: some View {
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
                    completionView
                    Spacer()
                }
                .padding()
            } else {
                VStack(spacing: 24) {
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

                    // Prompt
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

                    // Display the word as text
                    Text(correctWord)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.primary)

                    // Sound options
                    ForEach(0..<min(options.count, 4), id: \.self) { index in
                        soundOptionRow(index: index, isLandscape: false)
                    }

                    if !currentWordSet.isEmpty && !isShowingContinuePrompt {
                        progressBar
                    }

                    Text(feedback)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.bottom, 16)
                        .opacity(feedbackOpacity)
                        .animation(.easeInOut(duration: 0.5), value: feedbackOpacity)
                }
                .padding()
            }
        }
    }

    // MARK: - Shared Components

    func soundOptionRow(index: Int, isLandscape: Bool) -> some View {
        HStack(spacing: 12) {
            // Checkbox / radio button to select this as the answer
            Button(action: {
                guard !areButtonsDisabled else { return }
                selectedOption = options[index]
                checkAnswer(options[index], index: index)
            }) {
                Image(systemName: selectedOption == options[index] ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(selectedOption == options[index] ? .green : .gray)
            }
            .disabled(areButtonsDisabled)

            // Speaker button / word reveal area
            Button(action: {
                synthesizer.stopSpeaking(at: .immediate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    speak(word: options[index])
                }
            }) {
                Group {
                    if thinkingIndex == index, let revealed = revealedWord {
                        // Show the word spelling inside the button when wrong answer
                        Text(revealed)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)

                            Text("\(index + 1)")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: isLandscape ? 200 : 160, height: 60)
                .background(thinkingIndex == index ? Color.red.opacity(0.15) : Color.teal.opacity(0.15))
                .cornerRadius(16)
            }

            // Feedback emoji
            if celebrationIndex == index {
                Text("🎉")
                    .font(.title2)
            }
            if thinkingIndex == index {
                Text("🤔")
                    .font(.title2)
            }
        }
    }

    var progressBar: some View {
        HStack(spacing: 8) {
            Text(language == "fr-CA" ? "Progrès:" : "Progress:")
                .font(.caption2)
                .foregroundColor(.gray)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 4)
                    .cornerRadius(2)

                Rectangle()
                    .fill(Color.green)
                    .frame(width: 120 * CGFloat(masteredInCurrentSet) / CGFloat(max(totalInCurrentSet, 1)), height: 4)
                    .cornerRadius(2)
                    .animation(.spring(), value: masteredInCurrentSet)
            }

            Text("\(masteredInCurrentSet)/\(totalInCurrentSet)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.bottom, 8)
    }

    var completionView: some View {
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
    }

    // MARK: - Quiz Logic

    func loadWords() {
        allWords = language == "en-US" ? vocabManager.englishWords : vocabManager.frenchWords
        print("📚 SoundQuiz: Loaded \(allWords.count) total words for language: \(language)")
    }

    func setupInitialWordSet() {
        let allActiveWords = vocabManager.getActiveWords(for: language)
        print("📚 SoundQuiz: Setting up word set: \(allActiveWords.count) active words available")

        if allActiveWords.count > 9 {
            currentWordSet = Array(allActiveWords.prefix(10))
            remainingWords = Array(allActiveWords.dropFirst(10))
            totalInCurrentSet = currentWordSet.count
            masteredInCurrentSet = currentWordSet.filter { vocabManager.getMastery(for: $0, language: language) >= 2 }.count
        } else {
            currentWordSet = allActiveWords
            remainingWords = []
            totalInCurrentSet = currentWordSet.count
            masteredInCurrentSet = 0
        }
    }

    func updateLayoutForCurrentOrientation() {
        guard DeviceHelper.shouldAllowLandscape else {
            self.useLandscapeLayout = false
            return
        }

        let orientation = UIDevice.current.orientation
        if orientation == .portrait {
            self.useLandscapeLayout = false
        } else if orientation == .landscapeLeft || orientation == .landscapeRight {
            self.useLandscapeLayout = true
        }
    }

    func startQuizFlow() {
        // Check if we need to show continuation prompt
        if !isQuizzingAllWords && !remainingWords.isEmpty && activeWords.isEmpty {
            showContinuePrompt()
            return
        }

        guard !activeWords.isEmpty else {
            isCompleted = true
            feedback = language == "fr-CA"
                ? "Bravo \(userName)! Tu as maîtrisé tous les mots! 🎉🎉"
                : "Good job \(userName)! You've mastered all the words! 🎉🎉"
            correctWord = ""
            options = []

            ABCPal.playWhooshSound()

            let cleanFeedback = feedback.replacingOccurrences(of: "[\\p{Emoji}]", with: "", options: .regularExpression)
            speak(text: cleanFeedback)

            withAnimation(.spring()) {
                feedbackOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                goBack()
            }
            return
        }

        isCompleted = false
        isReady = false
        selectedOption = nil
        celebrationIndex = nil
        thinkingIndex = nil
        revealedWord = nil

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
        isFirstAttempt = true

        if !hasPlayedPrompt {
            speak(text: promptText)
            hasPlayedPrompt = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isReady = true
            }
        } else {
            isReady = true
        }
    }

    func checkAnswer(_ selected: String, index: Int) {
        if isShowingContinuePrompt {
            handleContinueResponse(selected)
            return
        }

        print("✅ SoundQuiz: User selected '\(selected)', correct word is '\(correctWord)'")
        areButtonsDisabled = true

        if selected.lowercased() == correctWord.lowercased() {
            print("✅ SoundQuiz: Correct answer!")
            if isFirstAttempt {
                let currentMastery = vocabManager.getMastery(for: correctWord, language: language)
                vocabManager.updateMastery(word: correctWord, language: language, count: currentMastery + 1)
                let count = currentMastery + 1

                if count == 2 && currentWordSet.contains(correctWord) {
                    masteredInCurrentSet += 1
                }

                if count == 1 {
                    celebrationIndex = index
                    speak(word: correctWord)
                } else {
                    feedback = language == "fr-CA" ? "Bravo!" : "Good job!"
                    speak(text: feedback)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        speak(word: correctWord)
                    }
                }
            } else {
                celebrationIndex = index
                speak(word: correctWord)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                celebrationIndex = nil
                startQuizFlow()
            }
        } else {
            print("❌ SoundQuiz: Wrong answer")
            thinkingIndex = index
            revealedWord = selected
            isFirstAttempt = false

            feedback = language == "fr-CA"
                ? "Non, essaie encore."
                : "No, try again."
            speak(text: feedback)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    feedbackOpacity = 0.0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                thinkingIndex = nil
                revealedWord = nil
                selectedOption = nil
                feedback = ""
                feedbackOpacity = 1.0
                areButtonsDisabled = false
            }
        }
    }

    func speak(text: String) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        utterance.preUtteranceDelay = 0.3
        synthesizer.speak(utterance)
    }

    func speak(word: String) {
        // Append a period to prevent the final consonant from being cut off by TTS
        let utterance = AVSpeechUtterance(string: word + ".")
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.25
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }


    func showContinuePrompt() {
        isShowingContinuePrompt = true
        isCompleted = false

        feedback = language == "fr-CA"
            ? "Bravo! Tu as terminé les 10 premiers mots! Veux-tu continuer avec les \(remainingWords.count) mots restants?"
            : "Great job! You've completed the first 10 words! Would you like to continue with the remaining \(remainingWords.count) words?"

        speak(text: feedback)

        correctWord = ""
        options = [language == "fr-CA" ? "Oui" : "Yes", language == "fr-CA" ? "Non" : "No"]
        areButtonsDisabled = false
    }

    func handleContinueResponse(_ response: String) {
        let isYes = (response == "Yes" || response == "Oui")

        if isYes {
            isQuizzingAllWords = true
            currentWordSet = remainingWords
            remainingWords = []
            totalInCurrentSet = currentWordSet.count
            masteredInCurrentSet = currentWordSet.filter { vocabManager.getMastery(for: $0, language: language) >= 2 }.count

            isShowingContinuePrompt = false
            feedback = ""
            hasPlayedPrompt = false
            startQuizFlow()
        } else {
            goBack()
        }
    }
}
