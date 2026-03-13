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
    @State private var showingCreateList = false
    @State private var newListName = ""
    @State private var listToRename: VocabList? = nil
    @State private var renameText = ""
    @State private var showingRenameAlert = false
    @State private var listToDelete: VocabList? = nil
    @State private var showingDeleteListConfirmation = false
    @State private var showingShareSheet = false
    @State private var shareFileURL: URL?

    var languageName: String {
        language == "en-US" ? "English" : "French"
    }

    var masteredWords: [String] {
        vocabManager.getMasteredWords(for: language)
    }

    var activeWords: [String] {
        vocabManager.getActiveWords(for: language)
    }

    var listsForLanguage: [VocabList] {
        vocabManager.listsForLanguage(language)
    }

    var body: some View {
        NavigationView {
            List {
                // Progress Stats
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

                // Actions
                Section(header: Text("Actions")) {
                    Button(action: {
                        showingCreateList = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Create New List")
                        }
                    }

                    Button(action: {
                        showingAddWords = true
                    }) {
                        HStack {
                            Image(systemName: "character.textbox")
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
                            Text("Reset Progress Only")
                        }
                        .foregroundColor(.orange)
                    }

                    Button(action: {
                        vocabManager.deleteAllWords(for: language)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Custom Words")
                        }
                        .foregroundColor(.red)
                    }
                }

                // Vocabulary Lists
                Section(header: Text("Lists")) {
                    if listsForLanguage.isEmpty {
                        Text("No vocabulary lists")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(listsForLanguage) { list in
                            NavigationLink(destination: VocabListDetailView(
                                listId: list.id,
                                language: language,
                                vocabManager: vocabManager
                            )) {
                                HStack {
                                    if list.isDefault {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    Text(list.name)
                                    Spacer()
                                    Text("\(list.words.count) words")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !list.isDefault {
                                    Button(role: .destructive) {
                                        listToDelete = list
                                        showingDeleteListConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        listToRename = list
                                        renameText = list.name
                                        showingRenameAlert = true
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    if let url = vocabManager.exportListToFile(id: list.id) {
                                        shareFileURL = url
                                        showingShareSheet = true
                                    }
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }

                // No Vocabulary fallback
                if activeWords.isEmpty && masteredWords.isEmpty {
                    Section(header: Text("No Vocabulary")) {
                        Button(action: {
                            vocabManager.restoreDefaultWords(for: language)
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                Text("Restore Default Words")
                            }
                            .foregroundColor(.blue)
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
        // Create New List alert
        .alert("Create New List", isPresented: $showingCreateList) {
            TextField("List name", text: $newListName)
            Button("Cancel", role: .cancel) { newListName = "" }
            Button("Create") {
                if !newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    _ = vocabManager.createList(name: newListName.trimmingCharacters(in: .whitespacesAndNewlines), language: language)
                }
                newListName = ""
            }
        }
        // Rename alert
        .alert("Rename List", isPresented: $showingRenameAlert) {
            TextField("New name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let list = listToRename, !renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    vocabManager.renameList(id: list.id, newName: renameText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        // Delete list confirmation
        .alert("Delete List?", isPresented: $showingDeleteListConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let list = listToDelete {
                    vocabManager.deleteList(id: list.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(listToDelete?.name ?? "")'? This cannot be undone.")
        }
        // Add custom words sheet
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
        // Import from text sheet
        .sheet(isPresented: $showingImportSheet) {
            NavigationView {
                VStack {
                    Text("Import Vocabulary from Text")
                        .font(.headline)
                        .padding()

                    Text("Paste text from a book or document. Words will be extracted automatically. Proper nouns (names, places) are detected and keep their capitalization.")
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
        // Share sheet
        .background(
            Group {
                if let url = shareFileURL {
                    ActivityViewController(activityItems: [url], isPresented: $showingShareSheet)
                }
            }
        )
        // Import result alert
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
