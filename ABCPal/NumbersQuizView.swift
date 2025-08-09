//
//  NumbersQuizView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation

struct NumbersQuizView: View {
    var language: String
    var goBack: () -> Void
    
    @State private var currentNumber = 1
    @State private var options: [Int] = []
    @State private var feedback = ""
    @State private var celebrationNumber: Int? = nil
    @State private var thinkingNumber: Int? = nil
    @State private var areButtonsDisabled = false
    @State private var feedbackOpacity = 1.0
    @State private var isCompleted = false
    @State private var isFirstAttempt = true
    @State private var useLandscapeLayout = false
    @State private var mastery: [Int: Int] = [:]
    @State private var isAutoPlayMode = false
    @State private var inactivityTimer: Timer? = nil
    @State private var autoPlayTimer: Timer? = nil
    @State private var isWaitingForNext = false
    
    let synthesizer = AVSpeechSynthesizer()
    
    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }
    
    var promptText: String {
        language == "fr-CA" ? "Trouve le nombre" : "Find the number"
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isCompleted {
                VStack(spacing: 30) {
                    Text("🎉🎉🎉")
                        .font(.system(size: 80))
                        .scaleEffect(1.2)
                    
                    Text(feedback)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    HStack(spacing: 30) {
                        Button(action: {
                            // User interaction - stop autoplay before going back
                            stopAutoPlay()
                            synthesizer.stopSpeaking(at: .immediate)
                            goBack()
                        }) {
                            HStack {
                                Image(systemName: "arrow.backward")
                                Text(language == "fr-CA" ? "Terminé" : "Done")
                            }
                            .font(.title2)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Reset for another round
                            isCompleted = false
                            mastery.removeAll()
                            startQuizFlow()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(language == "fr-CA" ? "Pratiquer encore" : "Practice More")
                            }
                            .font(.title2)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            } else if useLandscapeLayout && geometry.size.width > geometry.size.height {
                HStack {
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
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            // Left side with prompt and speaker
                            VStack(alignment: .leading, spacing: 30) {
                                if !isCompleted {
                                    Button(action: {
                                        // User interaction - exit autoplay and reset timer
                                        stopAutoPlay()
                                        resetInactivityTimer()
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
                                        // User interaction - exit autoplay and reset timer
                                        stopAutoPlay()
                                        resetInactivityTimer()
                                        synthesizer.stopSpeaking(at: .immediate)
                                        speak(number: currentNumber)
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
                                // Right side with number options
                                VStack(spacing: 20) {
                                    if !options.isEmpty {
                                        ForEach(0..<min(options.count, 4), id: \.self) { index in
                                            Button(action: {
                                                checkAnswer(options[index])
                                            }) {
                                                HStack {
                                                    Text("\(options[index])")
                                                        .font(.title2)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.blue)
                                                    
                                                    if celebrationNumber == options[index] {
                                                        Text("🎉")
                                                            .font(.title2)
                                                    }
                                                    if thinkingNumber == options[index] {
                                                        Text("🤔")
                                                            .font(.title2)
                                                    }
                                                    // Show pointing emoji in autoplay mode for correct answer
                                                    if isAutoPlayMode && options[index] == currentNumber {
                                                        Text("👈")
                                                            .font(.title2)
                                                    }
                                                }
                                                .frame(minWidth: 120, minHeight: 50)
                                                .background(Color.gray.opacity(0.15))
                                                .cornerRadius(12)
                                            }
                                            .disabled(areButtonsDisabled)
                                        }
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width * 0.4)
                                .padding(.trailing, 20)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
            } else {
                VStack(spacing: 30) {
                    HStack {
                        Button(action: {
                            // User interaction - stop autoplay before going back
                            stopAutoPlay()
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
                            // User interaction - exit autoplay and reset timer
                            stopAutoPlay()
                            resetInactivityTimer()
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
                            speak(number: currentNumber)
                        }) {
                            Text("🔊")
                                .font(.system(size: 100))
                        }
                        .padding(.bottom, 20)
                    }
                    
                    Spacer()
                    
                    if !isCompleted && !options.isEmpty {
                        VStack(spacing: 20) {
                            ForEach(0..<min(options.count, 4), id: \.self) { index in
                                Button(action: {
                                    checkAnswer(options[index])
                                }) {
                                    HStack {
                                        Text("\(options[index])")
                                            .font(.title2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        if celebrationNumber == options[index] {
                                            Text("🎉")
                                                .font(.title2)
                                        }
                                        if thinkingNumber == options[index] {
                                            Text("🤔")
                                                .font(.title2)
                                        }
                                        // Show pointing emoji in autoplay mode for correct answer
                                        if isAutoPlayMode && options[index] == currentNumber {
                                            Text("👈")
                                                .font(.title2)
                                        }
                                    }
                                    .frame(minWidth: 200, minHeight: 50)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(12)
                                }
                                .disabled(areButtonsDisabled)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            startQuizFlow()
            checkOrientation()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            checkOrientation()
        }
    }
    
    func checkOrientation() {
        // Check if device allows landscape
        guard DeviceHelper.shouldAllowLandscape else {
            // Force portrait layout on small screens
            self.useLandscapeLayout = false
            print("📱 NumbersQuizView: Small screen detected, forcing portrait layout")
            return
        }
        
        // Allow landscape on iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.useLandscapeLayout = true
        } else {
            // Check actual orientation for larger iPhones
            let orientation = UIDevice.current.orientation
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                self.useLandscapeLayout = true
            } else if orientation == .portrait {
                self.useLandscapeLayout = false
            }
        }
    }
    
    func checkAnswer(_ selected: Int) {
        // User interaction - exit autoplay mode and reset timers
        stopAutoPlay()
        resetInactivityTimer()
        
        areButtonsDisabled = true
        
        if selected == currentNumber {
            // Only count as mastery if first attempt
            if isFirstAttempt {
                let currentMastery = mastery[currentNumber] ?? 0
                mastery[currentNumber] = currentMastery + 1
                let count = currentMastery + 1
                
                if count == 1 {
                    celebrationNumber = selected
                    speak(number: currentNumber)
                } else {
                    feedback = language == "fr-CA" ? "Bravo!" : "Good job!"
                    speak(text: feedback)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        speak(number: currentNumber)
                    }
                }
            } else {
                // Not first attempt, just acknowledge
                celebrationNumber = selected
                speak(number: currentNumber)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                celebrationNumber = nil
                startQuizFlow()
            }
        } else {
            thinkingNumber = selected
            isFirstAttempt = false
            
            feedback = language == "fr-CA" ? "Non, c'est \(selected)." : "No, that is \(selected)."
            speak(text: feedback)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    feedbackOpacity = 0.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                thinkingNumber = nil
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
    
    func speak(number: Int) {
        let utterance = AVSpeechUtterance(string: String(number))
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.3
        synthesizer.speak(utterance)
    }
    
    func startQuizFlow() {
        // Don't stop autoplay if we're already in autoplay mode (continuing to next question)
        let wasInAutoPlay = isAutoPlayMode
        if !wasInAutoPlay {
            stopAutoPlay()
        }
        
        // Get all numbers that haven't been mastered twice
        let unmasteredNumbers = (1...100).filter { (mastery[$0] ?? 0) < 2 }
        
        guard !unmasteredNumbers.isEmpty else {
            isCompleted = true
            feedback = language == "fr-CA" 
                ? "Bravo \(userName)! Tu as maîtrisé tous les nombres de 1 à 100! 🎉🎉"
                : "Good job \(userName)! You've mastered all numbers 1-100! 🎉🎉"
            
            playWhooshSound()
            
            let cleanFeedback = feedback.replacingOccurrences(of: "[\\p{Emoji}]", with: "", options: .regularExpression)
            speak(text: cleanFeedback)
            
            return
        }
        
        // Reset for new question
        isFirstAttempt = true
        feedbackOpacity = 1.0
        feedback = ""
        celebrationNumber = nil
        thinkingNumber = nil
        areButtonsDisabled = false
        
        // Select a random unmastered number
        currentNumber = unmasteredNumbers.randomElement()!
        
        // Generate options
        generateOptions()
        
        // Speak the prompt
        speak(text: promptText)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            speak(number: currentNumber)
        }
        
        // Handle autoplay or start inactivity timer
        if wasInAutoPlay {
            // Continue autoplay after current number is shown
            isWaitingForNext = true
            autoPlayTimer?.invalidate()
            autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.isWaitingForNext = false
                if self.isAutoPlayMode {
                    self.startQuizFlow()
                }
            }
        } else {
            // Start inactivity timer for autoplay
            resetInactivityTimer()
        }
    }
    
    func generateOptions() {
        var newOptions: [Int] = [currentNumber]
        
        // Add 3 more random numbers
        while newOptions.count < 4 {
            var randomNumber: Int
            
            // Create numbers that are somewhat close to the current number
            let range = min(20, currentNumber / 2)
            let minValue = max(1, currentNumber - range)
            let maxValue = min(100, currentNumber + range)
            
            randomNumber = Int.random(in: minValue...maxValue)
            
            if !newOptions.contains(randomNumber) {
                newOptions.append(randomNumber)
            }
        }
        
        options = newOptions.shuffled()
    }
    
    // MARK: - AutoPlay Functions
    
    func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            if !areButtonsDisabled && !isCompleted && !options.isEmpty {
                startAutoPlay()
            }
        }
    }
    
    func startAutoPlay() {
        isAutoPlayMode = true
        
        // Repeat the number sound
        speak(number: currentNumber)
        
        // Set waiting flag to show visual indicator
        isWaitingForNext = true
        
        // Move to next number after a 5-second delay
        autoPlayTimer?.invalidate()
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            self.isWaitingForNext = false
            if self.isAutoPlayMode {
                self.startQuizFlow()
            }
        }
    }
    
    func stopAutoPlay() {
        isAutoPlayMode = false
        isWaitingForNext = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
}