//
//  VocabularyManagementView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI

struct VocabularyManagementView: View {
    @Binding var isShowing: Bool
    let language: String
    
    @StateObject private var vocabManager = VocabularyManager.shared
    @State private var showingImportSheet = false
    @State private var importText = ""
    @State private var showingAddWords = false
    @State private var newWords = ""
    @State private var importResult: (added: Int, duplicates: Int)? = nil
    @State private var showingImportResult = false
    
    var languageName: String {
        language == "en-US" ? "English" : "French"
    }
    
    var masteredWords: [String] {
        vocabManager.getMasteredWords(for: language)
    }
    
    var activeWords: [String] {
        vocabManager.getActiveWords(for: language)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Vocabulary Progress")) {
                    HStack {
                        Text("Total Words")
                        Spacer()
                        Text("\(activeWords.count + masteredWords.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Words to Learn")
                        Spacer()
                        Text("\(activeWords.count)")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Mastered Words")
                        Spacer()
                        Text("\(masteredWords.count)")
                            .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button(action: {
                        showingAddWords = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Custom Words")
                        }
                    }
                    
                    Button(action: {
                        showingImportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Import from Text")
                        }
                    }
                    
                    Button(action: {
                        vocabManager.resetMastery(for: language)
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Progress")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                if !masteredWords.isEmpty {
                    Section(header: Text("Mastered Words (\(masteredWords.count))")) {
                        ForEach(masteredWords, id: \.self) { word in
                            HStack {
                                Text(word)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(languageName) Vocabulary")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isShowing = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddWords) {
            NavigationView {
                VStack {
                    Text("Add Custom Words")
                        .font(.headline)
                        .padding()
                    
                    Text("Enter words separated by commas or new lines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $newWords)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                    
                    Button(action: {
                        let words = newWords
                            .replacingOccurrences(of: ",", with: "\n")
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        
                        let result = vocabManager.addCustomWords(words, language: language)
                        importResult = result
                        newWords = ""
                        showingAddWords = false
                        if result.added > 0 || result.duplicates > 0 {
                            showingImportResult = true
                        }
                    }) {
                        Text("Add Words")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(newWords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddWords = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            NavigationView {
                VStack {
                    Text("Import Vocabulary from Text")
                        .font(.headline)
                        .padding()
                    
                    Text("Paste text from a book or document. Words will be extracted automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextEditor(text: $importText)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                    
                    Button(action: {
                        let result = vocabManager.importVocabularyFromText(importText, language: language)
                        importResult = result
                        importText = ""
                        showingImportSheet = false
                        if result.added > 0 || result.duplicates > 0 {
                            showingImportResult = true
                        }
                    }) {
                        Text("Import")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingImportSheet = false
                    }
                )
            }
        }
        .alert(isPresented: $showingImportResult) {
            let result = importResult ?? (0, 0)
            var message = ""
            if result.added > 0 {
                message += "Added \(result.added) new word\(result.added == 1 ? "" : "s")"
            }
            if result.duplicates > 0 {
                if !message.isEmpty { message += "\n" }
                message += "Skipped \(result.duplicates) duplicate\(result.duplicates == 1 ? "" : "s")"
            }
            if message.isEmpty {
                message = "No new words were added"
            }
            
            return Alert(
                title: Text("Import Complete"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}