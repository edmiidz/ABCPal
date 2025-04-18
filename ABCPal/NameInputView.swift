//
//  NameInputView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/17/25.
//

import SwiftUI
import AVFoundation

struct NameInputView: View {
    @Binding var userName: String
    var onComplete: () -> Void
    
    @State private var inputName: String = ""
    @State private var hasSpoken = false
    let synthesizer = AVSpeechSynthesizer()
    
    let prompt = "Welcome! What's your name?"
    
    var body: some View {
        VStack(spacing: 30) {
            // Welcome prompt with speaker
            Button(action: {
                synthesizer.stopSpeaking(at: .immediate)
                speak(text: prompt, language: "en-US")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text(prompt)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            
            // Name input field
            TextField("Your name", text: $inputName)
                .font(.title3)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .autocapitalization(.words)
                .disableAutocorrection(true)
            
            // Continue button
            Button(action: {
                if !inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    userName = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
                    onComplete()
                }
            }) {
                Text("Continue")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
        }
        .padding()
        .onAppear {
            if !hasSpoken {
                speak(text: prompt, language: "en-US")
                hasSpoken = true
            }
        }
    }
    
    func speak(text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}
