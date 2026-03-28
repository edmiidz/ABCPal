//
//  ImageReaderView.swift
//  ABCPal
//
//  Unified view for displaying an image, running OCR, reading text aloud,
//  and capturing vocabulary. Used by both the in-app photo picker flow
//  and the share extension flow.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct ImageReaderView: View {
    let image: UIImage
    let language: String
    let onDismiss: () -> Void
    /// When true, shows a photo picker button to select a new image
    var allowNewPhoto: Bool = false
    /// Called when user picks a new photo (only used when allowNewPhoto is true)
    var onNewImage: ((UIImage) -> Void)?

    @StateObject private var vocabManager = VocabularyManager.shared
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var showingVocabCapture = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let ocrService = OCRService()
    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top bar
                HStack {
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward")
                            Text(backLabel)
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
                    ProgressView(processingLabel)
                        .padding()
                } else {
                    // Display recognized text or no text message
                    if !recognizedText.isEmpty {
                        Text(recognizedText)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    } else {
                        Text(noTextLabel)
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding()
                            .multilineTextAlignment(.center)
                    }

                    // Action buttons
                    VStack(spacing: 15) {
                        // Read aloud
                        Button(action: readTextAloud) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                Text(readAloudLabel)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(recognizedText.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(recognizedText.isEmpty)

                        // Capture vocabulary
                        Button(action: { showingVocabCapture = true }) {
                            HStack {
                                Image(systemName: "text.badge.plus")
                                Text(captureVocabLabel)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(recognizedText.isEmpty ? Color.gray : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(recognizedText.isEmpty)

                        // New photo (in-app flow) or Close (share flow)
                        if allowNewPhoto {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text(newPhotoLabel)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }

                            Button(action: openCameraApp) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text(openCameraLabel)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }

                            Text(cameraGuidanceLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Button(action: {
                                synthesizer.stopSpeaking(at: .immediate)
                                onDismiss()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text(closeLabel)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear { startOCR() }
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem = newItem else { return }
            newItem.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    selectedPhotoItem = nil
                    if case .success(let data) = result,
                       let data = data,
                       let uiImage = UIImage(data: data) {
                        let fixed = fixImageOrientation(uiImage)
                        onNewImage?(fixed)
                    }
                }
            }
        }
        .sheet(isPresented: $showingVocabCapture) {
            VocabCaptureView(
                text: recognizedText,
                language: language,
                onComplete: { words in
                    let result = vocabManager.addCustomWords(words, language: language)
                    print("Added \(result.added) words, skipped \(result.duplicates) duplicates")
                }
            )
        }
    }

    // MARK: - OCR

    private func startOCR() {
        isProcessing = true
        let fixed = fixImageOrientation(image)
        let processed = language == "ja-JP" ? fixed : (enhanceImageForOCR(fixed) ?? fixed)
        guard let cgImage = processed.cgImage else {
            isProcessing = false
            recognizedText = ""
            return
        }

        ocrService.performOCR(on: cgImage, language: language) { text in
            DispatchQueue.main.async {
                recognizedText = text ?? ""
                isProcessing = false
                if !recognizedText.isEmpty {
                    readTextAloud()
                }
            }
        }
    }

    // MARK: - TTS

    private func readTextAloud() {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: recognizedText)
        utterance.voice = voiceForLanguage(language)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    // MARK: - Camera App

    private func openCameraApp() {
        if let url = URL(string: "camera://") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Image Processing

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

    // MARK: - Localized Labels

    private var backLabel: String {
        switch language {
        case "fr-CA": return "Retour"
        case "ja-JP": return "戻る"
        default: return "Back"
        }
    }

    private var processingLabel: String {
        switch language {
        case "fr-CA": return "Lecture du texte..."
        case "ja-JP": return "テキストを読み取り中..."
        default: return "Reading text..."
        }
    }

    private var noTextLabel: String {
        switch language {
        case "fr-CA": return "Aucun texte reconnu. Essayez une nouvelle photo."
        case "ja-JP": return "テキストが認識されませんでした。新しい写真を撮ってください。"
        default: return "No text recognized. Try a new photo."
        }
    }

    private var readAloudLabel: String {
        switch language {
        case "fr-CA": return "Lire à haute voix"
        case "ja-JP": return "読み上げ"
        default: return "Read Aloud"
        }
    }

    private var captureVocabLabel: String {
        switch language {
        case "fr-CA": return "Capturer le vocabulaire"
        case "ja-JP": return "語彙をキャプチャ"
        default: return "Capture Vocabulary"
        }
    }

    private var newPhotoLabel: String {
        switch language {
        case "fr-CA": return "Choisir une photo"
        case "ja-JP": return "写真を選ぶ"
        default: return "Pick a Photo"
        }
    }

    private var openCameraLabel: String {
        switch language {
        case "fr-CA": return "Ouvrir l'appareil photo"
        case "ja-JP": return "カメラを開く"
        default: return "Open Camera"
        }
    }

    private var cameraGuidanceLabel: String {
        switch language {
        case "fr-CA": return "Prenez une photo, recadrez-la, puis partagez-la dans ABCPal"
        case "ja-JP": return "写真を撮って、トリミングして、ABCPalに共有してください"
        default: return "Take a photo, crop it, then share it back into ABCPal"
        }
    }

    private var closeLabel: String {
        switch language {
        case "fr-CA": return "Fermer"
        case "ja-JP": return "閉じる"
        default: return "Close"
        }
    }
}
