//
//  ProperNounDetector.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 2/26/26.
//

import NaturalLanguage

struct ProperNounDetector {

    /// Detects proper nouns (personal names, place names, organization names) in text using NLTagger.
    /// Returns a set of lowercased words that NLTagger identified as names.
    /// - Parameters:
    ///   - text: The full text to analyze (sentence context improves accuracy)
    ///   - language: The app language code (e.g., "en-US", "fr-CA")
    /// - Returns: A set of lowercased words identified as proper nouns
    static func detectProperNouns(in text: String, language: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        // Map app language codes to NLLanguage
        let nlLanguage: NLLanguage
        switch language {
        case "fr-CA":
            nlLanguage = .french
        default:
            nlLanguage = .english
        }
        tagger.setLanguage(nlLanguage, range: text.startIndex..<text.endIndex)

        var properNouns = Set<String>()

        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType,
                            options: options) { tag, tokenRange in
            if let tag = tag,
               tag == .personalName || tag == .placeName || tag == .organizationName {
                let word = String(text[tokenRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !word.isEmpty {
                    properNouns.insert(word.lowercased())
                }
            }
            return true
        }

        return properNouns
    }
}
