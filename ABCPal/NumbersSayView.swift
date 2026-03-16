//
//  NumbersSayView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 3/13/26.
//

import SwiftUI
import AVFoundation

struct NumbersSayView: View {
    var language: String
    var goBack: () -> Void

    @State private var typedNumber = ""
    @State private var displayedNumber = ""
    @State private var isSpeaking = false
    @State private var speakTimer: Timer? = nil

    let synthesizer = AVSpeechSynthesizer()

    var promptText: String {
        language == "fr-CA" ? "Tape un nombre" : "Type a number"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with back button
            HStack {
                Button(action: {
                    speakTimer?.invalidate()
                    speakTimer = nil
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

                // Clear button
                if !typedNumber.isEmpty {
                    Button(action: {
                        speakTimer?.invalidate()
                        speakTimer = nil
                        synthesizer.stopSpeaking(at: .immediate)
                        typedNumber = ""
                        displayedNumber = ""
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text(language == "fr-CA" ? "Effacer" : "Clear")
                        }
                        .padding(8)
                        .foregroundColor(.red)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Prompt
            Text(promptText)
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.top, 20)

            Spacer()

            // Large number display
            Text(displayedNumber.isEmpty ? " " : displayedNumber)
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

            // Speaking indicator
            if isSpeaking {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.blue)
                    Text(language == "fr-CA" ? "Lecture..." : "Speaking...")
                        .foregroundColor(.blue)
                }
                .font(.title3)
                .padding(.top, 10)
            }

            Spacer()

            // Number pad
            VStack(spacing: 12) {
                ForEach(0..<3) { row in
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { col in
                            let digit = row * 3 + col
                            numberButton(digit: "\(digit)")
                        }
                    }
                }

                // Bottom row: empty, 0, backspace
                HStack(spacing: 12) {
                    // Empty space
                    Color.clear
                        .frame(width: 80, height: 60)

                    numberButton(digit: "0")

                    // Backspace button
                    Button(action: {
                        if !typedNumber.isEmpty {
                            speakTimer?.invalidate()
                            speakTimer = nil
                            synthesizer.stopSpeaking(at: .immediate)
                            typedNumber.removeLast()
                            displayedNumber = typedNumber
                            scheduleSpeak()
                        }
                    }) {
                        Image(systemName: "delete.backward.fill")
                            .font(.title2)
                            .frame(width: 80, height: 60)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .onDisappear {
            speakTimer?.invalidate()
            speakTimer = nil
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    func numberButton(digit: String) -> some View {
        Button(action: {
            // Limit to reasonable number length
            guard typedNumber.count < 10 else { return }

            speakTimer?.invalidate()
            speakTimer = nil
            synthesizer.stopSpeaking(at: .immediate)

            typedNumber += digit
            displayedNumber = typedNumber

            scheduleSpeak()
        }) {
            Text(digit)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .frame(width: 80, height: 60)
                .background(Color.cyan.opacity(0.15))
                .cornerRadius(12)
        }
    }

    func scheduleSpeak() {
        guard !typedNumber.isEmpty else { return }

        speakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            speakNumber(typedNumber)
        }
    }

    func speakNumber(_ numberString: String) {
        guard !numberString.isEmpty else { return }

        isSpeaking = true
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: numberString)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.3
        synthesizer.speak(utterance)

        // Estimate speech duration and reset indicator
        let estimatedDuration = max(1.0, Double(numberString.count) * 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
            isSpeaking = false
        }
    }
}
