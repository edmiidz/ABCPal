//
//  SharedImageCaptureView.swift
//  ABCPal
//
//  Handles images shared into the app via the iOS share sheet.
//

import SwiftUI
import AVFoundation

struct SharedImageCaptureView: View {
    let image: UIImage
    let onDismiss: () -> Void

    @StateObject private var vocabManager = VocabularyManager.shared
    @State private var selectedLanguage: String?
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var showingVocabCapture = false

    private let ocrService = OCRService()
    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        if let language = selectedLanguage {
            // OCR result screen (mirrors BookReaderView text display)
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            synthesizer.stopSpeaking(at: .immediate)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text(language == "fr-CA" ? "Fermer" : "Close")
                            }
                            .padding(8)
                            .foregroundColor(.blue)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    if isProcessing {
                        ProgressView(language == "fr-CA" ? "Lecture du texte..." : "Reading text...")
                            .padding()
                    } else {
                        if !recognizedText.isEmpty {
                            Text(recognizedText)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        } else {
                            Text(language == "fr-CA" ? "Aucun texte reconnu." : "No text recognized.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .padding()
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 15) {
                            Button(action: { readTextAloud(language: language) }) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text(language == "fr-CA" ? "Lire à haute voix" : "Read Aloud")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(recognizedText.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(recognizedText.isEmpty)

                            Button(action: { showingVocabCapture = true }) {
                                HStack {
                                    Image(systemName: "text.badge.plus")
                                    Text(language == "fr-CA" ? "Capturer le vocabulaire" : "Capture Vocabulary")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(recognizedText.isEmpty ? Color.gray : Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(recognizedText.isEmpty)

                            Button(action: {
                                synthesizer.stopSpeaking(at: .immediate)
                                onDismiss()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text(language == "fr-CA" ? "Fermer" : "Close")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemBackground))
            .sheet(isPresented: $showingVocabCapture) {
                let _ = print("Sheet presenting VocabCaptureView with text length: \(recognizedText.count), language: \(language)")
                VocabCaptureView(
                    text: recognizedText,
                    language: language,
                    onComplete: { words in
                        let result = vocabManager.addCustomWords(words, language: language)
                        print("Shared image: added \(result.added) words, skipped \(result.duplicates) duplicates")
                    }
                )
            }
        } else {
            // Language picker
            VStack(spacing: 30) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .padding(.horizontal)

                Text("Choose language")
                    .font(.headline)

                HStack(spacing: 30) {
                    Button(action: { startOCR(language: "en-US") }) {
                        VStack {
                            Text("🇺🇸")
                                .font(.system(size: 50))
                            Text("English")
                                .font(.headline)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(16)
                    }

                    Button(action: { startOCR(language: "fr-CA") }) {
                        VStack {
                            Text("🇫🇷")
                                .font(.system(size: 50))
                            Text("Français")
                                .font(.headline)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(16)
                    }
                }

                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(.red)
                .padding(.top, 10)
            }
            .padding()
        }
    }

    private func startOCR(language: String) {
        selectedLanguage = language
        isProcessing = true

        let fixed = fixImageOrientation(image)
        guard let enhanced = enhanceImageForOCR(fixed),
              let cgImage = enhanced.cgImage else {
            isProcessing = false
            recognizedText = ""
            return
        }

        ocrService.performOCR(on: cgImage) { text in
            DispatchQueue.main.async {
                recognizedText = text ?? ""
                isProcessing = false
                if !recognizedText.isEmpty {
                    readTextAloud(language: language)
                }
            }
        }
    }

    private func readTextAloud(language: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: recognizedText)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalized
    }

    private func enhanceImageForOCR(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey)
        filter?.setValue(0.1, forKey: kCIInputBrightnessKey)
        if let output = filter?.outputImage {
            let context = CIContext()
            if let cg = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
            }
        }
        return image
    }
}
