//
//  VocabCaptureViews.swift
//  ABCPal
//
//  Extracted from BookReaderView.swift
//

import SwiftUI

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
    @ObservedObject private var vocabManager = VocabularyManager.shared

    // Extract words while preserving original case for display, excluding existing vocabulary
    var extractedWords: [(original: String, lowercase: String)] {
        let words = text
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { $0.count > 2 }
            .filter { !$0.isEmpty }

        // Get existing vocabulary words (lowercased) to filter duplicates
        let existingWords: Set<String> = {
            let vocabWords = language == "en-US" ? vocabManager.englishWords : vocabManager.frenchWords
            return Set(vocabWords.map { $0.lowercased() })
        }()

        // Create pairs of original and lowercase, removing duplicates based on lowercase
        var uniqueWords: [String: String] = [:] // lowercase: original
        for word in words {
            let lower = word.lowercased()
            // Skip words already in vocabulary and internal duplicates
            if uniqueWords[lower] == nil && !existingWords.contains(lower) {
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

                Group {
                    if extractedWords.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text(language == "fr-CA" ? "Tous les mots sont déjà dans votre vocabulaire!" : "All words are already in your vocabulary!")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Spacer()
                        }
                    } else {
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
                    }
                }
                .onAppear {
                    if !hasInitialized {
                        let rawWords = text
                            .components(separatedBy: .whitespacesAndNewlines)
                            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
                            .filter { $0.count > 2 && !$0.isEmpty }
                        let existingCount = (language == "en-US" ? vocabManager.englishWords : vocabManager.frenchWords).count
                        print("VocabCaptureView onAppear: text length=\(text.count), language=\(language), rawWords=\(rawWords.count), existingVocab=\(existingCount), extractedWords=\(extractedWords.count)")
                        if extractedWords.isEmpty && !rawWords.isEmpty {
                            let existing = Set((language == "en-US" ? vocabManager.englishWords : vocabManager.frenchWords).map { $0.lowercased() })
                            let filtered = rawWords.filter { existing.contains($0.lowercased()) }
                            print("VocabCaptureView: All \(rawWords.count) words already in vocab! Sample existing matches: \(filtered.prefix(10))")
                        }
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
