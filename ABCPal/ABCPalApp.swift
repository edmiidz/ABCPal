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
    @State private var sharedText: String?

    init() {
        print("ABCPal App Starting...")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleIncomingFile(url: url)
                }
                .task {
                    // One-time check on launch for pending shared content
                    // Slight delay to let URL handler fire first if applicable
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await checkForSharedContent()
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
                .fullScreenCover(item: Binding<IdentifiableText?>(
                    get: { sharedText.map { IdentifiableText(text: $0) } },
                    set: { sharedText = $0?.text }
                )) { item in
                    SharedTextView(text: item.text) {
                        sharedText = nil
                    }
                }
        }
    }

    private func handleIncomingFile(url: URL) {
        print("ABCPal: handleIncomingFile called with URL: \(url)")
        // Handle custom URL scheme from Share Extension
        if url.scheme == "abcpal" {
            print("ABCPal: Received abcpal:// URL, host=\(url.host ?? "nil")")
            // Small delay to ensure the extension has finished writing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if url.host == "shared-image" {
                    self.loadSharedImageFromAppGroup()
                } else if url.host == "shared-text" {
                    self.loadSharedTextFromAppGroup()
                }
            }
            return
        }

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

    @MainActor
    private func checkForSharedContent() async {
        print("ABCPal: checkForSharedContent called")
        // Try multiple times in case the share extension hasn't finished writing yet
        for attempt in 1...3 {
            if sharedImage == nil {
                loadSharedImageFromAppGroup()
            }
            if sharedText == nil {
                loadSharedTextFromAppGroup()
            }
            if sharedImage != nil || sharedText != nil {
                print("ABCPal: Found shared content on attempt \(attempt)")
                break
            }
            if attempt < 3 {
                print("ABCPal: No shared content found on attempt \(attempt), retrying...")
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    private func loadSharedImageFromAppGroup() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.edmiidz.ABCPal"
        ) else {
            print("ABCPal: Cannot access app group container")
            return
        }

        let fileURL = containerURL.appendingPathComponent("shared_image.png")
        print("ABCPal: Checking for shared image at: \(fileURL.path)")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ABCPal: No shared image file found")
            return
        }

        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attrs?[.size] as? Int ?? 0
        print("ABCPal: Found shared image file, size: \(fileSize) bytes")

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            print("ABCPal: Failed to load image from file")
            return
        }

        // Clean up the file after loading
        try? FileManager.default.removeItem(at: fileURL)

        sharedImage = image
        print("ABCPal: Loaded shared image from app group (\(image.size.width)x\(image.size.height))")
    }

    private func loadSharedTextFromAppGroup() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.edmiidz.ABCPal"
        ) else {
            print("ABCPal: Cannot access app group container for text")
            return
        }

        let fileURL = containerURL.appendingPathComponent("shared_text.txt")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8),
              !text.isEmpty else {
            return
        }

        // Clean up the file after loading
        try? FileManager.default.removeItem(at: fileURL)

        sharedText = text
        print("ABCPal: Loaded shared text from app group")
    }
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct IdentifiableText: Identifiable {
    let id = UUID()
    let text: String
}
