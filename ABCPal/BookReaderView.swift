//
//  BookReaderView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation

struct BookReaderView: View {
    var language: String
    var goBack: () -> Void
    
    @StateObject private var cameraService = CameraService()
    @StateObject private var vocabManager = VocabularyManager.shared
    
    @State private var capturedImage: UIImage?
    @State private var isShowingCropView = false
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var showingVocabCapture = false
    @State private var capturedWords: [String] = []
    
    let synthesizer = AVSpeechSynthesizer()
    let ocrService = OCRService()
    
    var userName: String {
        UserDefaults.standard.string(forKey: "userNameKey") ?? "Student"
    }
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraService.isSetup && capturedImage == nil {
                CameraView(cameraService: cameraService)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Top bar with back button
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
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Instruction text
                    Text(language == "fr-CA" ? "Prenez une photo d'une page de livre" : "Take a photo of a book page")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    
                    // Capture button
                    Button(action: capturePhoto) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 50)
                }
            } else if let image = capturedImage, !isShowingCropView {
                // Text display view
                ScrollView {
                    VStack(spacing: 20) {
                        // Back button
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
                        
                        if isProcessing {
                            ProgressView(language == "fr-CA" ? "Lecture du texte..." : "Reading text...")
                                .padding()
                        } else if !recognizedText.isEmpty {
                            // Display recognized text
                            Text(recognizedText)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            
                            // Action buttons
                            VStack(spacing: 15) {
                                // Read aloud button
                                Button(action: readTextAloud) {
                                    HStack {
                                        Image(systemName: "speaker.wave.2.fill")
                                        Text(language == "fr-CA" ? "Lire à haute voix" : "Read Aloud")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                // Capture vocabulary button
                                Button(action: {
                                    showingVocabCapture = true
                                }) {
                                    HStack {
                                        Image(systemName: "text.badge.plus")
                                        Text(language == "fr-CA" ? "Capturer le vocabulaire" : "Capture Vocabulary")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                // New photo button
                                Button(action: {
                                    capturedImage = nil
                                    recognizedText = ""
                                }) {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text(language == "fr-CA" ? "Nouvelle photo" : "New Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Crop view overlay
            if isShowingCropView, let image = capturedImage {
                CropView(
                    image: .constant(image),
                    isShowingCropView: $isShowingCropView,
                    onCropComplete: processCroppedImage
                )
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
    
    func capturePhoto() {
        cameraService.takePhoto { image in
            if let image = image {
                self.capturedImage = image
                self.isShowingCropView = true
            }
        }
    }
    
    func processCroppedImage(_ croppedImage: UIImage) {
        isProcessing = true
        
        guard let cgImage = croppedImage.cgImage else {
            isProcessing = false
            return
        }
        
        ocrService.performOCR(on: cgImage) { text in
            DispatchQueue.main.async {
                self.recognizedText = text ?? ""
                self.isProcessing = false
                
                // Auto-read if text was found
                if !self.recognizedText.isEmpty {
                    self.readTextAloud()
                }
            }
        }
    }
    
    func readTextAloud() {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: recognizedText)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
}

// Camera View wrapper
struct CameraView: UIViewRepresentable {
    @ObservedObject var cameraService: CameraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraService.session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}

// Vocabulary capture view
struct VocabCaptureView: View {
    let text: String
    let language: String
    let onComplete: ([String]) -> Void
    
    @State private var selectedWords: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    
    var extractedWords: [String] {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { $0.count > 2 }
            .filter { !$0.isEmpty }
        
        return Array(Set(words)).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(language == "fr-CA" ? "Sélectionnez les mots à ajouter" : "Select words to add")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(extractedWords, id: \.self) { word in
                            Button(action: {
                                if selectedWords.contains(word) {
                                    selectedWords.remove(word)
                                } else {
                                    selectedWords.insert(word)
                                }
                            }) {
                                Text(word)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedWords.contains(word) ? Color.purple : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedWords.contains(word) ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                
                HStack {
                    Button(language == "fr-CA" ? "Annuler" : "Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(language == "fr-CA" ? "Ajouter \(selectedWords.count) mots" : "Add \(selectedWords.count) words") {
                        onComplete(Array(selectedWords))
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedWords.isEmpty)
                    .padding()
                    .foregroundColor(.white)
                    .background(selectedWords.isEmpty ? Color.gray : Color.purple)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// Crop View
struct CropView: View {
    @Binding var image: UIImage?
    @Binding var isShowingCropView: Bool
    var onCropComplete: (UIImage) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var moveStep: CGFloat = 20
    @State private var showOCRGuide: Bool = true
    
    var body: some View {
        VStack {
            Text("Position the text within the box")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
            
            GeometryReader { geometry in
                ZStack {
                    Color.black
                    
                    if let displayImage = image {
                        Image(uiImage: displayImage)
                            .resizable()
                            .scaledToFit()
                            .offset(offset)
                    }
                    
                    ZStack {
                        Rectangle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.6)
                            
                        if showOCRGuide {
                            Rectangle()
                                .stroke(Color.yellow, lineWidth: 2)
                                .frame(width: geometry.size.width * 0.55, height: geometry.size.height * 0.55)
                        }
                    }
                    .background(Color.white.opacity(0.05))
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.4)
            
            Toggle("Show OCR boundary guide", isOn: $showOCRGuide)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // Direction controls
            VStack(spacing: 10) {
                Button(action: { offset.height -= moveStep }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20))
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                
                HStack(spacing: 30) {
                    Button(action: { offset.width -= moveStep }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Button(action: { offset.width += moveStep }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20))
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
                
                Button(action: { offset.height += moveStep }) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 20))
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 5)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    isShowingCropView = false
                }
                .frame(width: 100, height: 44)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
                    .frame(width: 30)
                
                Button("Process This Text") {
                    processImage()
                }
                .frame(width: 160, height: 44)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func processImage() {
        guard let currentImage = image else { return }
        
        let screenSize = UIScreen.main.bounds.size
        let imageSize = currentImage.size
        let imageAspect = imageSize.width / imageSize.height
        let screenAspect = screenSize.width / screenSize.height
        
        var scaledImageSize: CGSize
        if imageAspect > screenAspect {
            scaledImageSize = CGSize(width: screenSize.height * imageAspect, height: screenSize.height)
        } else {
            scaledImageSize = CGSize(width: screenSize.width, height: screenSize.width / imageAspect)
        }
        
        let centerX = screenSize.width / 2
        let centerY = screenSize.height * 0.3
        
        let cropWidth = screenSize.width * 0.55 * (imageSize.width / scaledImageSize.width)
        let cropHeight = screenSize.height * 0.4 * 0.55 * (imageSize.height / scaledImageSize.height)
        
        let cropX = ((centerX - (screenSize.width * 0.55 / 2)) - offset.width) * (imageSize.width / scaledImageSize.width)
        let cropY = ((centerY - (screenSize.height * 0.4 * 0.55 / 2)) - offset.height) * (imageSize.height / scaledImageSize.height)
        
        let validX = max(0, min(imageSize.width - cropWidth, cropX))
        let validY = max(0, min(imageSize.height - cropHeight, cropY))
        
        let paddedX = max(0, validX - (cropWidth * 0.1))
        let paddedY = max(0, validY - (cropHeight * 0.1))
        let paddedWidth = min(imageSize.width - paddedX, cropWidth * 1.2)
        let paddedHeight = min(imageSize.height - paddedY, cropHeight * 1.2)
        
        let paddedCropRect = CGRect(
            x: paddedX,
            y: paddedY,
            width: paddedWidth,
            height: paddedHeight
        )
        
        if let cgImage = currentImage.cgImage,
           let croppedCGImage = cgImage.cropping(to: paddedCropRect) {
            let croppedImage = UIImage(cgImage: croppedCGImage)
            onCropComplete(croppedImage)
            isShowingCropView = false
        }
    }
}