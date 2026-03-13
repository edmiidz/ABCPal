//
//  VocabList.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 3/12/26.
//

import Foundation

struct VocabList: Identifiable, Codable {
    var id: UUID
    var name: String
    var language: String
    var words: [String]
    var isDefault: Bool
    var createdDate: Date

    init(id: UUID = UUID(), name: String, language: String, words: [String] = [], isDefault: Bool = false, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.language = language
        self.words = words
        self.isDefault = isDefault
        self.createdDate = createdDate
    }
}

struct VocabListExport: Codable {
    var name: String
    var language: String
    var words: [String]

    init(from list: VocabList) {
        self.name = list.name
        self.language = list.language
        self.words = list.words
    }
}
