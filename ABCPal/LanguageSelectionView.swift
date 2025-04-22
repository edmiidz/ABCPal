//
//  LanguageSelectionView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

struct LanguageSelectionView: View {
    var onLanguageSelected: (String) -> Void
    var userName: String

    @State private var hasSpoken = false
    @State private var showingMenu = false
    @State private var showingAbout = false
    @State private var showingShare = false
    @State private var showingNameChange = false
    
    let synthesizer = AVSpeechSynthesizer()

    var englishPrompt: String {
        "\(userName), Which language do you want to learn your ABCs in today?"
    }
    
    var frenchPrompt: String {
        "\(userName), Dans quelle langue veux-tu apprendre ton alphabet aujourd'hui?"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Menu button row at the very top
            HStack {
                Button(action: {
                    showingMenu = true
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Spacer for vertical distribution
            Spacer()
            
            // Language prompts group
            VStack(spacing: 25) {
                // English prompt with speaker
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speakText(englishPrompt, language: "en-US")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text(englishPrompt)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // French prompt with speaker
                Button(action: {
                    synthesizer.stopSpeaking(at: .immediate)
                    speakText(frenchPrompt, language: "fr-CA")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text(frenchPrompt)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            // Another spacer for vertical distribution
            Spacer()

            // Language selection buttons group
            VStack(spacing: 30) {
                // English option with TTS button
                HStack {
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        playWhooshSound()
                        onLanguageSelected("en-US")
                    }) {
                        Text("🇺🇸 English Alphabet")
                            .font(.title2)
                            .frame(minWidth: 200, minHeight: 60)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        speakText("English Alphabet", language: "en-US")
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(8)
                    }
                }

                // French option with TTS button
                HStack {
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        onLanguageSelected("fr-CA")
                    }) {
                        Text("🇫🇷 Alphabet Français")
                            .font(.title2)
                            .frame(minWidth: 200, minHeight: 60)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        speakText("Alphabet Français", language: "fr-CA")
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // Final spacer
            Spacer()
        }
        .onAppear {
            if !hasSpoken {
                // Only play the English prompt on first appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.speakText(self.englishPrompt, language: "en-US")
                    self.hasSpoken = true
                }
            }
        }
        .sheet(isPresented: $showingMenu) {
            MenuModalView(
                showingMenu: $showingMenu,
                showingAbout: $showingAbout,
                showingShare: $showingShare,
                showingNameChange: $showingNameChange
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showingAbout) {
            AlphaAboutView(isShowing: $showingAbout)
        }
        .fullScreenCover(isPresented: $showingShare) {
            AlphaShareView(isShowing: $showingShare)
        }
        .sheet(isPresented: $showingNameChange) {
            ChangeUsernameView(isShowing: $showingNameChange)
        }
    }
    
    func speakText(_ text: String, language: String) {
        // First make sure any current speech is completely stopped
        synthesizer.stopSpeaking(at: .immediate)
        
        // Small delay to ensure the previous speech is fully stopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let utterance = AVSpeechUtterance(string: text)
            
            // Try to get the voice, or use a fallback
            if let voice = AVSpeechSynthesisVoice(language: language) {
                utterance.voice = voice
            } else if language.starts(with: "en") {
                utterance.voice = AVSpeechSynthesisVoice(language: "en")
            } else if language.starts(with: "fr") {
                utterance.voice = AVSpeechSynthesisVoice(language: "fr")
            }
            
            utterance.rate = 0.4
            self.synthesizer.speak(utterance)
        }
    }
}

// MARK: - Menu Views

struct MenuModalView: View {
    @Binding var showingMenu: Bool
    @Binding var showingAbout: Bool
    @Binding var showingShare: Bool
    @Binding var showingNameChange: Bool
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    showingMenu = false
                    showingAbout = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("About ABCPal")
                    }
                }
                
                Button(action: {
                    showingMenu = false
                    showingShare = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share App")
                    }
                }
                
                Button(action: {
                    showingMenu = false
                    showingNameChange = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Change Username")
                    }
                }
            }
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingMenu = false
                    }
                }
            }
        }
    }
}

struct ChangeUsernameView: View {
    @Binding var isShowing: Bool
    @State private var newUserName: String = ""
    
    private let userNameKey = "userNameKey"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Change Your Name")
                    .font(.title)
                    .padding(.top)
                
                // Show current username
                if let currentName = UserDefaults.standard.string(forKey: userNameKey) {
                    Text("Current name: \(currentName)")
                        .foregroundColor(.gray)
                }
                
                TextField("New name", text: $newUserName)
                    .font(.title3)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                
                Button(action: {
                    saveUserName()
                    isShowing = false
                }) {
                    Text("Save")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Change Username")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isShowing = false
                    }
                }
            }
            .onAppear {
                // Load current username when view appears
                if let name = UserDefaults.standard.string(forKey: userNameKey) {
                    newUserName = name
                }
            }
        }
    }
    
    func saveUserName() {
        let trimmedName = newUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            // Save to UserDefaults
            UserDefaults.standard.set(trimmedName, forKey: userNameKey)
            
            // Post notification to update the app
            NotificationCenter.default.post(name: NSNotification.Name("UserNameChanged"), object: nil)
        }
    }
}

struct AlphaAboutView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Image("splashImage")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding()
                    
                    AlphaInfoRow(icon: "abc", title: "Purpose", content: "ABCPal helps children learn the alphabet in English and French")
                    
                    AlphaInfoRow(icon: "person.2.fill", title: "Target Audience", content: "Children ages 3-6 learning their letters")
                    
                    AlphaInfoRow(icon: "speaker.wave.3.fill", title: "Features", content: "Text-to-speech, interactive quizzes, and bilingual support")
                    
                    AlphaInfoRow(icon: "envelope.fill", title: "Support", content: "edmiidzapps@gmail.com")
                    
                    AlphaInfoRow(icon: "c.circle", title: "Copyright", content: "© 2025 Nik Edmiidz")
                    
                    AlphaInfoRow(icon: "1.circle", title: "Version", content: "1.0")
                }
                .padding()
            }
            .navigationTitle("About ABCPal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isShowing = false
                    }
                }
            }
        }
    }
}

struct AlphaInfoRow: View {
    var icon: String
    var title: String
    var content: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AlphaShareView: View {
    @Binding var isShowing: Bool
    @State private var showShareSheet = false
    let appURL = "https://apps.apple.com/us/app/abcpal/id6744830469"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Scan this QR code to download the app")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                AlphaQRCodeView(url: appURL)
                    .frame(width: 200, height: 200)
                    .padding()
                
                Text(appURL)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Link")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share ABCPal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isShowing = false
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: ["Check out ABCPal, a fun app to help kids learn the alphabet!", URL(string: appURL)!])
            }
        }
    }
}

struct AlphaQRCodeView: View {
    let url: String
    
    var body: some View {
        Image(uiImage: generateQRCode(from: url))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .background(Color.white)
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            let scale = UIScreen.main.scale
            let transform = CGAffineTransform(scaleX: scale * 10, y: scale * 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}   
