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
    @Published var vocabLists: [VocabList] = []

    private let englishWordsKey = "englishWordsKey"
    private let frenchWordsKey = "frenchWordsKey"
    private let englishMasteryKey = "englishMasteryKey"
    private let frenchMasteryKey = "frenchMasteryKey"
    private let customEnglishWordsKey = "customEnglishWordsKey"
    private let customFrenchWordsKey = "customFrenchWordsKey"
    private let vocabListsKey = "vocabListsKey"
    private let didMigrateToListsKey = "didMigrateToListsKey"

    init() {
        loadVocabLists()
        migrateToListsIfNeeded()
        rebuildDefaultLists()
        recomputeWordArrays()
        loadMastery()
    }

    // MARK: - Vocab Lists Persistence

    private func loadVocabLists() {
        if let data = UserDefaults.standard.data(forKey: vocabListsKey),
           let lists = try? JSONDecoder().decode([VocabList].self, from: data) {
            vocabLists = lists
        }
    }

    private func saveVocabLists() {
        if let data = try? JSONEncoder().encode(vocabLists) {
            UserDefaults.standard.set(data, forKey: vocabListsKey)
        }
    }

    // MARK: - Migration

    private func migrateToListsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: didMigrateToListsKey) else { return }

        // Migrate existing custom English words to a "My Words" list
        let customEnglish = UserDefaults.standard.stringArray(forKey: customEnglishWordsKey) ?? []
        if !customEnglish.isEmpty {
            let myEnglishList = VocabList(name: "My Words", language: "en-US", words: customEnglish)
            vocabLists.append(myEnglishList)
        }

        // Migrate existing custom French words to a "My Words" list
        let customFrench = UserDefaults.standard.stringArray(forKey: customFrenchWordsKey) ?? []
        if !customFrench.isEmpty {
            let myFrenchList = VocabList(name: "My Words", language: "fr-CA", words: customFrench)
            vocabLists.append(myFrenchList)
        }

        saveVocabLists()
        UserDefaults.standard.set(true, forKey: didMigrateToListsKey)
    }

    // MARK: - Default Lists (rebuilt from bundle on each launch)

    private func rebuildDefaultLists() {
        // Remove old default lists
        vocabLists.removeAll(where: { $0.isDefault })

        // Build English default list from bundle
        if let englishPath = Bundle.main.path(forResource: "english_vocab", ofType: "txt"),
           let englishContent = try? String(contentsOfFile: englishPath) {
            let words = englishContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            let defaultEnglish = VocabList(name: "Default", language: "en-US", words: words, isDefault: true)
            vocabLists.insert(defaultEnglish, at: 0)
        }

        // Build French default list from bundle
        if let frenchPath = Bundle.main.path(forResource: "french_vocab", ofType: "txt"),
           let frenchContent = try? String(contentsOfFile: frenchPath) {
            let words = frenchContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            let defaultFrench = VocabList(name: "Default", language: "fr-CA", words: words, isDefault: true)
            // Insert after English default if it exists
            let insertIndex = vocabLists.first?.isDefault == true ? 1 : 0
            vocabLists.insert(defaultFrench, at: insertIndex)
        }

        // Fallback if bundle loading fails
        if !vocabLists.contains(where: { $0.isDefault && $0.language == "en-US" }) {
            let filePath = "/Users/edmiidz/Projects/GitHub/ABCPal/ABCPal/english_vocab.txt"
            if let content = try? String(contentsOfFile: filePath) {
                let words = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                let defaultEnglish = VocabList(name: "Default", language: "en-US", words: words, isDefault: true)
                vocabLists.insert(defaultEnglish, at: 0)
            }
        }

        if !vocabLists.contains(where: { $0.isDefault && $0.language == "fr-CA" }) {
            let filePath = "/Users/edmiidz/Projects/GitHub/ABCPal/ABCPal/french_vocab.txt"
            if let content = try? String(contentsOfFile: filePath) {
                let words = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                let defaultFrench = VocabList(name: "Default", language: "fr-CA", words: words, isDefault: true)
                vocabLists.insert(defaultFrench, at: min(1, vocabLists.count))
            }
        }
    }

    // MARK: - Recompute merged word arrays (for quiz compatibility)

    func recomputeWordArrays() {
        let englishLists = vocabLists.filter { $0.language == "en-US" }
        let frenchLists = vocabLists.filter { $0.language == "fr-CA" }

        englishWords = Array(Set(englishLists.flatMap { $0.words })).sorted { $0.lowercased() < $1.lowercased() }
        frenchWords = Array(Set(frenchLists.flatMap { $0.words })).sorted { $0.lowercased() < $1.lowercased() }
    }

    // MARK: - Legacy loadVocabulary (now delegates to list system)

    func loadVocabulary() {
        rebuildDefaultLists()
        recomputeWordArrays()
    }

    // MARK: - List CRUD

    func createList(name: String, language: String) -> VocabList {
        let list = VocabList(name: name, language: language)
        vocabLists.append(list)
        saveVocabLists()
        return list
    }

    func renameList(id: UUID, newName: String) {
        if let index = vocabLists.firstIndex(where: { $0.id == id && !$0.isDefault }) {
            vocabLists[index].name = newName
            saveVocabLists()
        }
    }

    func deleteList(id: UUID) {
        vocabLists.removeAll(where: { $0.id == id && !$0.isDefault })
        saveVocabLists()
        recomputeWordArrays()
    }

    func addWordsToList(listId: UUID, words: [String]) -> (added: Int, duplicates: Int) {
        guard let index = vocabLists.firstIndex(where: { $0.id == listId }) else {
            return (0, 0)
        }

        let cleaned = words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let existingLowercase = Set(vocabLists[index].words.map { $0.lowercased() })

        var added = 0
        var duplicates = 0

        for word in Set(cleaned) {
            if existingLowercase.contains(word.lowercased()) {
                duplicates += 1
            } else {
                vocabLists[index].words.append(word)
                added += 1
            }
        }

        saveVocabLists()
        recomputeWordArrays()
        return (added: added, duplicates: duplicates)
    }

    func removeWordFromList(listId: UUID, word: String) {
        if let index = vocabLists.firstIndex(where: { $0.id == listId }) {
            vocabLists[index].words.removeAll { $0 == word }
            saveVocabLists()
            recomputeWordArrays()
        }
    }

    func listsForLanguage(_ language: String) -> [VocabList] {
        vocabLists.filter { $0.language == language }
    }

    // MARK: - "My Words" list helper (backward compat for BookReaderView OCR capture)

    private func myWordsList(for language: String) -> UUID {
        if let existing = vocabLists.first(where: { $0.name == "My Words" && $0.language == language && !$0.isDefault }) {
            return existing.id
        }
        let list = createList(name: "My Words", language: language)
        return list.id
    }

    // MARK: - Export / Import

    func exportList(id: UUID) -> Data? {
        guard let list = vocabLists.first(where: { $0.id == id }) else { return nil }
        let export = VocabListExport(from: list)
        return try? JSONEncoder().encode(export)
    }

    func exportListToFile(id: UUID) -> URL? {
        guard let list = vocabLists.first(where: { $0.id == id }),
              let data = exportList(id: id) else { return nil }

        let fileName = list.name.replacingOccurrences(of: " ", with: "_") + ".abcpal"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }

    func importList(from data: Data) -> VocabList? {
        guard let export = try? JSONDecoder().decode(VocabListExport.self, from: data) else { return nil }

        let list = VocabList(
            name: export.name,
            language: export.language,
            words: export.words
        )
        vocabLists.append(list)
        saveVocabLists()
        recomputeWordArrays()
        return list
    }

    func importList(from url: URL) -> VocabList? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return importList(from: data)
    }

    // MARK: - Mastery

    func loadMastery() {
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
        let masteryKey = word.lowercased()
        if language == "en-US" {
            englishMastery[masteryKey] = count
            saveMastery(for: language)
        } else if language == "fr-CA" {
            frenchMastery[masteryKey] = count
            saveMastery(for: language)
        }
    }

    func getMastery(for word: String, language: String) -> Int {
        let masteryKey = word.lowercased()
        if language == "en-US" {
            return englishMastery[masteryKey] ?? 0
        } else if language == "fr-CA" {
            return frenchMastery[masteryKey] ?? 0
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

    // MARK: - Backward-compatible addCustomWords (routes to "My Words" list)

    func addCustomWords(_ words: [String], language: String) -> (added: Int, duplicates: Int) {
        let listId = myWordsList(for: language)
        let result = addWordsToList(listId: listId, words: words)

        // Also persist to legacy custom words key for safety
        let key = language == "en-US" ? customEnglishWordsKey : customFrenchWordsKey
        let existing = UserDefaults.standard.stringArray(forKey: key) ?? []
        let cleaned = words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let existingLower = Set(existing.map { $0.lowercased() })
        let newWords = cleaned.filter { !existingLower.contains($0.lowercased()) }
        UserDefaults.standard.set(existing + newWords, forKey: key)

        return result
    }

    func importVocabularyFromText(_ text: String, language: String) -> (added: Int, duplicates: Int) {
        let properNouns = ProperNounDetector.detectProperNouns(in: text, language: language)

        let rawWords = text
            .components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { $0.count > 2 }
            .filter { !$0.isEmpty }

        let processedWords = rawWords.map { word -> String in
            if properNouns.contains(word.lowercased()) {
                return word
            }
            return word.lowercased()
        }

        return addCustomWords(Array(Set(processedWords)), language: language)
    }

    func getActiveWords(for language: String) -> [String] {
        let allWords = language == "en-US" ? englishWords : frenchWords
        let mastery = language == "en-US" ? englishMastery : frenchMastery
        return allWords.filter { (mastery[$0.lowercased()] ?? 0) < 2 }
    }

    func getMasteredWords(for language: String) -> [String] {
        let allWords = language == "en-US" ? englishWords : frenchWords
        let mastery = language == "en-US" ? englishMastery : frenchMastery
        return allWords.filter { (mastery[$0.lowercased()] ?? 0) >= 2 }
    }

    func deleteWord(_ word: String, language: String) {
        // Remove from all non-default lists for this language
        for i in vocabLists.indices where vocabLists[i].language == language && !vocabLists[i].isDefault {
            vocabLists[i].words.removeAll { $0 == word }
        }
        saveVocabLists()
        recomputeWordArrays()

        // Remove mastery
        if language == "en-US" {
            englishMastery.removeValue(forKey: word.lowercased())
            saveMastery(for: language)
        } else if language == "fr-CA" {
            frenchMastery.removeValue(forKey: word.lowercased())
            saveMastery(for: language)
        }

        // Also remove from legacy custom words
        let key = language == "en-US" ? customEnglishWordsKey : customFrenchWordsKey
        var customWords = UserDefaults.standard.stringArray(forKey: key) ?? []
        customWords.removeAll { $0 == word }
        UserDefaults.standard.set(customWords, forKey: key)
    }

    func deleteAllWords(for language: String) {
        // Remove all non-default lists for this language
        vocabLists.removeAll(where: { $0.language == language && !$0.isDefault })
        saveVocabLists()
        recomputeWordArrays()

        if language == "en-US" {
            UserDefaults.standard.removeObject(forKey: customEnglishWordsKey)
            englishMastery = [:]
            UserDefaults.standard.removeObject(forKey: englishMasteryKey)
        } else if language == "fr-CA" {
            UserDefaults.standard.removeObject(forKey: customFrenchWordsKey)
            frenchMastery = [:]
            UserDefaults.standard.removeObject(forKey: frenchMasteryKey)
        }
    }

    func restoreDefaultWords(for language: String) {
        // Clear custom words and lists
        vocabLists.removeAll(where: { $0.language == language && !$0.isDefault })

        if language == "en-US" {
            UserDefaults.standard.removeObject(forKey: customEnglishWordsKey)
            englishMastery = [:]
            UserDefaults.standard.removeObject(forKey: englishMasteryKey)
        } else if language == "fr-CA" {
            UserDefaults.standard.removeObject(forKey: customFrenchWordsKey)
            frenchMastery = [:]
            UserDefaults.standard.removeObject(forKey: frenchMasteryKey)
        }

        saveVocabLists()
        rebuildDefaultLists()
        recomputeWordArrays()
    }
}
