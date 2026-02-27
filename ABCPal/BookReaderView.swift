//
//  BookReaderView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation
import NaturalLanguage

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
            } else if capturedImage != nil && !isShowingCropView {
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
                                Text(language == "fr-CA" ? "Aucun texte reconnu. Essayez une nouvelle photo." : "No text recognized. Try a new photo.")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Action buttons - always visible
                            VStack(spacing: 15) {
                                // Read aloud button - only enabled if there's text
                                Button(action: readTextAloud) {
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
                                
                                // Capture vocabulary button - only enabled if there's text
                                Button(action: {
                                    showingVocabCapture = true
                                }) {
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
                                
                                // New photo button - always enabled
                                Button(action: {
                                    capturedImage = nil
                                    recognizedText = ""
                                    isShowingCropView = false
                                    isProcessing = false
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
                .background(Color(UIColor.systemBackground))
            }
            
        }
        .sheet(isPresented: $isShowingCropView) {
            if let image = capturedImage {
                CropView(
                    image: .constant(image),
                    isShowingCropView: $isShowingCropView,
                    onCropComplete: { croppedImage in
                        // Process immediately after cropping
                        processCroppedImage(croppedImage)
                    }
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
                // Fix image orientation for better OCR results
                self.capturedImage = self.fixImageOrientation(image)
                self.isShowingCropView = true
            }
        }
    }
    
    // Fix image orientation to ensure OCR works correctly
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    func processCroppedImage(_ croppedImage: UIImage) {
        print("Processing cropped image: \(croppedImage.size)")
        isProcessing = true
        
        // Enhance image for better OCR
        guard let enhancedImage = enhanceImageForOCR(croppedImage),
              let cgImage = enhancedImage.cgImage else {
            print("Failed to enhance image")
            isProcessing = false
            recognizedText = ""
            return
        }
        
        print("Enhanced image size: \(enhancedImage.size)")
        
        ocrService.performOCR(on: cgImage) { text in
            DispatchQueue.main.async {
                self.recognizedText = text ?? ""
                self.isProcessing = false
                print("OCR completed. Text length: \(self.recognizedText.count)")
                
                // Auto-read if text was found
                if !self.recognizedText.isEmpty {
                    self.readTextAloud()
                }
            }
        }
    }
    
    // Enhance image contrast and sharpness for better OCR
    private func enhanceImageForOCR(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey) // Increase contrast
        filter?.setValue(0.0, forKey: kCIInputSaturationKey) // Convert to grayscale
        filter?.setValue(0.1, forKey: kCIInputBrightnessKey) // Slightly increase brightness
        
        if let outputImage = filter?.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            }
        }
        
        return image
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
    @State private var showingProperNounView = false
    @State private var detectedProperNouns: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    @State private var hasInitialized = false
    
    // Extract words while preserving original case for display
    var extractedWords: [(original: String, lowercase: String)] {
        let words = text
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { $0.count > 2 }
            .filter { !$0.isEmpty }
        
        // Create pairs of original and lowercase, removing duplicates based on lowercase
        var uniqueWords: [String: String] = [:] // lowercase: original
        for word in words {
            let lower = word.lowercased()
            // Keep the original case version if we haven't seen this word yet
            if uniqueWords[lower] == nil {
                uniqueWords[lower] = word
            }
        }
        
        return uniqueWords.map { (original: $0.value, lowercase: $0.key) }
            .sorted { $0.lowercase < $1.lowercase }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text(language == "fr-CA" ? "Sélectionnez les mots à ajouter" : "Select words to add")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        if selectedWords.count == extractedWords.count {
                            // Deselect all
                            selectedWords.removeAll()
                        } else {
                            // Select all
                            selectedWords = Set(extractedWords.map { $0.lowercase })
                        }
                    }) {
                        Text(selectedWords.count == extractedWords.count ? 
                             (language == "fr-CA" ? "Désélectionner tout" : "Deselect All") :
                             (language == "fr-CA" ? "Sélectionner tout" : "Select All"))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(extractedWords, id: \.lowercase) { wordPair in
                            Button(action: {
                                if selectedWords.contains(wordPair.lowercase) {
                                    selectedWords.remove(wordPair.lowercase)
                                } else {
                                    selectedWords.insert(wordPair.lowercase)
                                }
                            }) {
                                Text(wordPair.original) // Show original case
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedWords.contains(wordPair.lowercase) ? Color.purple : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedWords.contains(wordPair.lowercase) ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if !hasInitialized {
                        // Initialize with all words selected
                        selectedWords = Set(extractedWords.map { $0.lowercase })
                        // Run NLTagger on full text for proper noun detection
                        detectedProperNouns = ProperNounDetector.detectProperNouns(in: text, language: language)
                        hasInitialized = true
                    }
                }
                
                HStack {
                    Button(language == "fr-CA" ? "Annuler" : "Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(language == "fr-CA" ? "Suivant" : "Next") {
                        // Check if any selected words start with capital letter
                        let capitalizedWords = extractedWords.filter { wordPair in
                            selectedWords.contains(wordPair.lowercase) &&
                            wordPair.original.first?.isUppercase == true
                        }

                        // Check if NLTagger detected any names among the capitalized words
                        let detectedAmongSelected = capitalizedWords.filter { wordPair in
                            detectedProperNouns.contains(wordPair.lowercase)
                        }

                        if !capitalizedWords.isEmpty && !detectedAmongSelected.isEmpty {
                            // Show proper noun view with NLTagger results for smart pre-selection
                            showingProperNounView = true
                        } else {
                            // No names detected — skip proper noun screen, add all as lowercase
                            onComplete(Array(selectedWords))
                            presentationMode.wrappedValue.dismiss()
                        }
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
        .sheet(isPresented: $showingProperNounView) {
            ProperNounSelectionView(
                words: extractedWords.filter { wordPair in
                    selectedWords.contains(wordPair.lowercase) &&
                    wordPair.original.first?.isUppercase == true
                },
                detectedProperNouns: detectedProperNouns,
                language: language,
                onComplete: { properNouns, regularWords in
                    // Get all originally selected words that weren't capitalized
                    let nonCapitalizedWords = extractedWords
                        .filter { wordPair in
                            selectedWords.contains(wordPair.lowercase) && 
                            wordPair.original.first?.isUppercase != true
                        }
                        .map { $0.lowercase }
                    
                    // Combine proper nouns (keep capitalized), regular words from capitalized selection, and non-capitalized words
                    let allWords = properNouns + regularWords + nonCapitalizedWords
                    onComplete(allWords)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Proper Noun Selection View
struct ProperNounSelectionView: View {
    let words: [(original: String, lowercase: String)]
    let detectedProperNouns: Set<String>
    let language: String
    let onComplete: ([String], [String]) -> Void

    @State private var properNouns: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    @State private var hasInitialized = false

    var body: some View {
        NavigationView {
            VStack {
                Text(language == "fr-CA" ? "Noms propres détectés" : "Proper nouns detected")
                    .font(.headline)
                    .padding(.top)
                    .padding(.horizontal)

                Text(language == "fr-CA" ? "Vérifiez et ajustez si nécessaire" : "Review and adjust if needed")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(words, id: \.lowercase) { wordPair in
                            Button(action: {
                                if properNouns.contains(wordPair.original) {
                                    properNouns.remove(wordPair.original)
                                } else {
                                    properNouns.insert(wordPair.original)
                                }
                            }) {
                                Text(properNouns.contains(wordPair.original) ? wordPair.original : wordPair.lowercase)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(properNouns.contains(wordPair.original) ? Color.orange : Color.gray.opacity(0.3))
                                    .foregroundColor(properNouns.contains(wordPair.original) ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    // Only pre-select words that NLTagger identified as names
                    if !hasInitialized {
                        properNouns = Set(words.filter { detectedProperNouns.contains($0.lowercase) }.map { $0.original })
                        hasInitialized = true
                    }
                }
                
                HStack {
                    Button(language == "fr-CA" ? "Retour" : "Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(language == "fr-CA" ? "Terminer" : "Done") {
                        // Separate proper nouns from regular words
                        let properNounsList = Array(properNouns)
                        let regularWords = words
                            .filter { !properNouns.contains($0.original) }
                            .map { $0.lowercase }
                        
                        onComplete(properNounsList, regularWords)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.purple)
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
                            .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.89)
                            
                        if showOCRGuide {
                            Rectangle()
                                .stroke(Color.yellow, lineWidth: 2)
                                .frame(width: geometry.size.width * 0.55, height: geometry.size.width * 0.84)
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
        
        // Get the actual view size from the geometry
        let viewSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.4)
        
        // Calculate how the image is displayed in the view
        let imageFrame = calculateImageFrame(image: currentImage, in: viewSize)
        
        // Calculate crop box in view coordinates (using inner guide dimensions)
        let cropBoxWidth = viewSize.width * 0.55
        let cropBoxHeight = viewSize.width * 0.84
        
        let cropBoxX = viewSize.width / 2 - cropBoxWidth / 2 - offset.width
        let cropBoxY = viewSize.height / 2 - cropBoxHeight / 2 - offset.height
        
        let cropFrame = CGRect(
            x: cropBoxX,
            y: cropBoxY,
            width: cropBoxWidth,
            height: cropBoxHeight
        )
        
        // Convert to image coordinates using proper transformation
        let cropRectInImage = convertToImageCoordinates(
            cropRect: cropFrame,
            imageFrame: imageFrame,
            imageSize: currentImage.size
        )
        
        // Add padding for better OCR results
        let padding = cropRectInImage.width * 0.1
        let paddedRect = CGRect(
            x: max(0, cropRectInImage.minX - padding),
            y: max(0, cropRectInImage.minY - padding),
            width: min(currentImage.size.width - (cropRectInImage.minX - padding), cropRectInImage.width + padding * 2),
            height: min(currentImage.size.height - (cropRectInImage.minY - padding), cropRectInImage.height + padding * 2)
        )
        
        // Perform the cropping
        if let cgImage = currentImage.cgImage,
           let croppedCGImage = cgImage.cropping(to: paddedRect) {
            let croppedImage = UIImage(cgImage: croppedCGImage, scale: currentImage.scale, orientation: .up)
            onCropComplete(croppedImage)
            isShowingCropView = false
        }
    }
    
    // Calculate the frame for the image when scaled to fit
    private func calculateImageFrame(image: UIImage, in size: CGSize) -> CGRect {
        let imageAspect = image.size.width / image.size.height
        let frameAspect = size.width / size.height
        
        if imageAspect > frameAspect {
            // Image is wider than frame
            let scaledHeight = size.width / imageAspect
            return CGRect(
                x: 0,
                y: (size.height - scaledHeight) / 2,
                width: size.width,
                height: scaledHeight
            )
        } else {
            // Image is taller than frame
            let scaledWidth = size.height * imageAspect
            return CGRect(
                x: (size.width - scaledWidth) / 2,
                y: 0,
                width: scaledWidth,
                height: size.height
            )
        }
    }
    
    // Convert view coordinates to image coordinates
    private func convertToImageCoordinates(cropRect: CGRect, imageFrame: CGRect, imageSize: CGSize) -> CGRect {
        // Ensure crop rect is within image frame
        let validCropRect = cropRect.intersection(imageFrame)
        
        // Handle empty intersection
        if validCropRect.isEmpty {
            return CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        }
        
        // Calculate relative positions within the frame
        let relX = (validCropRect.minX - imageFrame.minX) / imageFrame.width
        let relY = (validCropRect.minY - imageFrame.minY) / imageFrame.height
        let relWidth = validCropRect.width / imageFrame.width
        let relHeight = validCropRect.height / imageFrame.height
        
        // Convert to image coordinates
        return CGRect(
            x: max(0, relX * imageSize.width),
            y: max(0, relY * imageSize.height),
            width: min(imageSize.width - (relX * imageSize.width), relWidth * imageSize.width),
            height: min(imageSize.height - (relY * imageSize.height), relHeight * imageSize.height)
        )
    }
}