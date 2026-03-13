//
//  ABCPalApp.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/18/25.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct ABCPalApp: App {
    @StateObject private var vocabManager = VocabularyManager.shared
    @State private var importedListName: String?
    @State private var showingImportAlert = false
    @State private var importError = false
    @State private var sharedImage: UIImage?

    init() {
        print("ABCPal App Starting...")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleIncomingFile(url: url)
                }
                .alert("Vocabulary List Imported", isPresented: $showingImportAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    if importError {
                        Text("Could not import the vocabulary list. The file may be invalid.")
                    } else {
                        Text("'\(importedListName ?? "List")' has been added to your vocabulary.")
                    }
                }
                .fullScreenCover(item: Binding<IdentifiableImage?>(
                    get: { sharedImage.map { IdentifiableImage(image: $0) } },
                    set: { sharedImage = $0?.image }
                )) { item in
                    SharedImageCaptureView(image: item.image) {
                        sharedImage = nil
                    }
                }
        }
    }

    private func handleIncomingFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() || true else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        // Check if this is an image file
        if let typeID = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let utType = UTType(typeID),
           utType.conforms(to: .image) {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                sharedImage = image
            }
            return
        }

        // Check by extension as fallback
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff", "webp"]
        if imageExtensions.contains(url.pathExtension.lowercased()) {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                sharedImage = image
            }
            return
        }

        // Handle .abcpal vocab list files
        if let list = vocabManager.importList(from: url) {
            importedListName = list.name
            importError = false
        } else {
            importedListName = nil
            importError = true
        }
        showingImportAlert = true
    }
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
