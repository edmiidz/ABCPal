//
//  VocabListDetailView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 3/12/26.
//

import SwiftUI

struct VocabListDetailView: View {
    let listId: UUID
    let language: String
    @ObservedObject var vocabManager: VocabularyManager

    @State private var showingAddWords = false
    @State private var newWords = ""
    @State private var showingShareSheet = false
    @State private var shareFileURL: URL?
    @State private var importResult: (added: Int, duplicates: Int)? = nil
    @State private var showingImportResult = false
    @State private var wordToDelete: String? = nil
    @State private var showingDeleteConfirmation = false

    var vocabList: VocabList? {
        vocabManager.vocabLists.first(where: { $0.id == listId })
    }

    var body: some View {
        Group {
            if let list = vocabList {
                List {
                    Section(header: Text("Info")) {
                        HStack {
                            Text("Words")
                            Spacer()
                            Text("\(list.words.count)")
                                .foregroundColor(.secondary)
                        }

                        if !list.isDefault {
                            HStack {
                                Text("Created")
                                Spacer()
                                Text(list.createdDate, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if !list.words.isEmpty {
                        Section(header: Text("Words (\(list.words.count))")) {
                            ForEach(list.words.sorted { $0.lowercased() < $1.lowercased() }, id: \.self) { word in
                                HStack {
                                    Text(word)
                                    Spacer()
                                    let mastery = vocabManager.getMastery(for: word, language: language)
                                    if mastery >= 2 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else if mastery == 1 {
                                        Image(systemName: "circle.bottomhalf.filled")
                                            .foregroundColor(.orange)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    if !list.isDefault {
                                        Button(role: .destructive) {
                                            vocabManager.removeWordFromList(listId: listId, word: word)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            Text("No words in this list yet.")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle(list.name)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if !list.isDefault {
                                Button {
                                    showingAddWords = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }

                            Button {
                                if let url = vocabManager.exportListToFile(id: listId) {
                                    shareFileURL = url
                                    showingShareSheet = true
                                }
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
            } else {
                Text("List not found")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingAddWords) {
            NavigationView {
                VStack {
                    Text("Add Words to List")
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

                        let result = vocabManager.addWordsToList(listId: listId, words: words)
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
        .background(
            Group {
                if let url = shareFileURL {
                    ActivityViewController(activityItems: [url], isPresented: $showingShareSheet)
                }
            }
        )
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
                title: Text("Words Added"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
