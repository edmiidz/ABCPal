//
//  VocabularyManager.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import Foundation

class VocabularyManager: ObservableObject {
    static let shared = VocabularyManager()
    
    @Published var englishWords: [String] = []
    @Published var frenchWords: [String] = []
    @Published var englishMastery: [String: Int] = [:]
    @Published var frenchMastery: [String: Int] = [:]
    
    private let englishWordsKey = "englishWordsKey"
    private let frenchWordsKey = "frenchWordsKey"
    private let englishMasteryKey = "englishMasteryKey"
    private let frenchMasteryKey = "frenchMasteryKey"
    private let customEnglishWordsKey = "customEnglishWordsKey"
    private let customFrenchWordsKey = "customFrenchWordsKey"
    
    init() {
        loadVocabulary()
        loadMastery()
    }
    
    func loadVocabulary() {
        // Load default vocabulary from files
        if let englishPath = Bundle.main.path(forResource: "english_vocab", ofType: "txt"),
           let englishContent = try? String(contentsOfFile: englishPath) {
            let defaultEnglish = englishContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            // Add custom words if any
            let customEnglish = UserDefaults.standard.stringArray(forKey: customEnglishWordsKey) ?? []
            englishWords = Array(Set(defaultEnglish + customEnglish)).sorted()
        }
        
        if let frenchPath = Bundle.main.path(forResource: "french_vocab", ofType: "txt"),
           let frenchContent = try? String(contentsOfFile: frenchPath) {
            let defaultFrench = frenchContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            // Add custom words if any
            let customFrench = UserDefaults.standard.stringArray(forKey: customFrenchWordsKey) ?? []
            frenchWords = Array(Set(defaultFrench + customFrench)).sorted()
        }
        
        // Fallback if bundle loading fails
        if englishWords.isEmpty {
            let filePath = "/Users/edmiidz/Projects/GitHub/ABCPal/ABCPal/english_vocab.txt"
            if let content = try? String(contentsOfFile: filePath) {
                englishWords = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            }
        }
        
        if frenchWords.isEmpty {
            let filePath = "/Users/edmiidz/Projects/GitHub/ABCPal/ABCPal/french_vocab.txt"
            if let content = try? String(contentsOfFile: filePath) {
                frenchWords = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            }
        }
    }
    
    func loadMastery() {
        // Load mastery data from UserDefaults
        if let englishData = UserDefaults.standard.dictionary(forKey: englishMasteryKey) as? [String: Int] {
            englishMastery = englishData
        }
        
        if let frenchData = UserDefaults.standard.dictionary(forKey: frenchMasteryKey) as? [String: Int] {
            frenchMastery = frenchData
        }
    }
    
    func saveMastery(for language: String) {
        if language == "en-US" {
            UserDefaults.standard.set(englishMastery, forKey: englishMasteryKey)
        } else if language == "fr-CA" {
            UserDefaults.standard.set(frenchMastery, forKey: frenchMasteryKey)
        }
    }
    
    func updateMastery(word: String, language: String, count: Int) {
        if language == "en-US" {
            englishMastery[word] = count
            saveMastery(for: language)
        } else if language == "fr-CA" {
            frenchMastery[word] = count
            saveMastery(for: language)
        }
    }
    
    func getMastery(for word: String, language: String) -> Int {
        if language == "en-US" {
            return englishMastery[word] ?? 0
        } else if language == "fr-CA" {
            return frenchMastery[word] ?? 0
        }
        return 0
    }
    
    func resetMastery(for language: String) {
        if language == "en-US" {
            englishMastery = [:]
            UserDefaults.standard.removeObject(forKey: englishMasteryKey)
        } else if language == "fr-CA" {
            frenchMastery = [:]
            UserDefaults.standard.removeObject(forKey: frenchMasteryKey)
        }
    }
    
    func addCustomWords(_ words: [String], language: String) -> (added: Int, duplicates: Int) {
        let cleanedWords = words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        
        let uniqueNewWords = Set(cleanedWords)
        var addedCount = 0
        var duplicateCount = 0
        
        if language == "en-US" {
            let existingWords = Set(englishWords)
            let existingCustom = UserDefaults.standard.stringArray(forKey: customEnglishWordsKey) ?? []
            
            // Count new vs duplicate words
            for word in uniqueNewWords {
                if existingWords.contains(word) {
                    duplicateCount += 1
                } else {
                    addedCount += 1
                }
            }
            
            // Only add truly new words
            let newWordsToAdd = uniqueNewWords.subtracting(existingWords)
            let allCustom = Array(Set(existingCustom + Array(newWordsToAdd)))
            UserDefaults.standard.set(allCustom, forKey: customEnglishWordsKey)
            
            // Reload vocabulary to include new words
            englishWords = Array(Set(englishWords + Array(newWordsToAdd))).sorted()
        } else if language == "fr-CA" {
            let existingWords = Set(frenchWords)
            let existingCustom = UserDefaults.standard.stringArray(forKey: customFrenchWordsKey) ?? []
            
            // Count new vs duplicate words
            for word in uniqueNewWords {
                if existingWords.contains(word) {
                    duplicateCount += 1
                } else {
                    addedCount += 1
                }
            }
            
            // Only add truly new words
            let newWordsToAdd = uniqueNewWords.subtracting(existingWords)
            let allCustom = Array(Set(existingCustom + Array(newWordsToAdd)))
            UserDefaults.standard.set(allCustom, forKey: customFrenchWordsKey)
            
            // Reload vocabulary to include new words
            frenchWords = Array(Set(frenchWords + Array(newWordsToAdd))).sorted()
        }
        
        return (added: addedCount, duplicates: duplicateCount)
    }
    
    func importVocabularyFromText(_ text: String, language: String) -> (added: Int, duplicates: Int) {
        // Parse text into words (could be from BookReaderOCR or other sources)
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { $0.count > 2 } // Only words with more than 2 characters
            .filter { !$0.isEmpty }
        
        return addCustomWords(Array(Set(words)), language: language)
    }
    
    func getActiveWords(for language: String) -> [String] {
        let allWords = language == "en-US" ? englishWords : frenchWords
        let mastery = language == "en-US" ? englishMastery : frenchMastery
        
        // Filter out words that have been mastered (2+ correct on first attempt)
        return allWords.filter { (mastery[$0] ?? 0) < 2 }
    }
    
    func getMasteredWords(for language: String) -> [String] {
        let allWords = language == "en-US" ? englishWords : frenchWords
        let mastery = language == "en-US" ? englishMastery : frenchMastery
        
        // Return words that have been mastered
        return allWords.filter { (mastery[$0] ?? 0) >= 2 }
    }
}