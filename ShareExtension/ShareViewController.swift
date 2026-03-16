//
//  ShareViewController.swift
//  ShareExtension
//
//  Receives images or text from the iOS share sheet, saves them to an App Group
//  container, then opens the main ABCPal app via a custom URL scheme.
//

import UIKit
import Social
import UniformTypeIdentifiers
import MobileCoreServices

class ShareViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                // Check for images first
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, error in
                        guard let self = self else { return }
                        if let error = error {
                            print("ShareExtension: Error loading image: \(error)")
                            self.close()
                            return
                        }

                        var image: UIImage?

                        if let url = data as? URL,
                           let imgData = try? Data(contentsOf: url) {
                            image = UIImage(data: imgData)
                        } else if let imgData = data as? Data {
                            image = UIImage(data: imgData)
                        } else if let img = data as? UIImage {
                            image = img
                        }

                        guard let finalImage = image else {
                            self.close()
                            return
                        }

                        self.saveImageAndOpenApp(image: finalImage)
                    }
                    return
                }

                // Check for text (plain text or URL)
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, error in
                        guard let self = self else { return }
                        if let error = error {
                            print("ShareExtension: Error loading text: \(error)")
                            self.close()
                            return
                        }

                        var text: String?

                        if let string = data as? String {
                            text = string
                        } else if let url = data as? URL {
                            text = url.absoluteString
                        } else if let data = data as? Data {
                            text = String(data: data, encoding: .utf8)
                        }

                        guard let finalText = text, !finalText.isEmpty else {
                            self.close()
                            return
                        }

                        self.saveTextAndOpenApp(text: finalText)
                    }
                    return
                }
            }
        }

        close()
    }

    private func saveImageAndOpenApp(image: UIImage) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.edmiidz.ABCPal"
        ) else {
            print("ShareExtension: Cannot access app group container")
            close()
            return
        }

        let fileURL = containerURL.appendingPathComponent("shared_image.png")
        try? FileManager.default.removeItem(at: fileURL)

        guard let data = image.pngData() else {
            close()
            return
        }

        do {
            try data.write(to: fileURL)
            print("ShareExtension: Image saved to \(fileURL.path)")
        } catch {
            print("ShareExtension: Failed to save image: \(error)")
            close()
            return
        }

        openApp(with: "abcpal://shared-image")
    }

    private func saveTextAndOpenApp(text: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.edmiidz.ABCPal"
        ) else {
            print("ShareExtension: Cannot access app group container")
            close()
            return
        }

        let fileURL = containerURL.appendingPathComponent("shared_text.txt")
        try? FileManager.default.removeItem(at: fileURL)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("ShareExtension: Text saved to \(fileURL.path)")
        } catch {
            print("ShareExtension: Failed to save text: \(error)")
            close()
            return
        }

        openApp(with: "abcpal://shared-text")
    }

    private func openApp(with urlString: String) {
        guard let url = URL(string: urlString) else {
            close()
            return
        }

        // Use the responder chain to open the URL
        let selector = NSSelectorFromString("openURL:")
        var responder: UIResponder? = self
        while responder != nil {
            if responder!.responds(to: selector) {
                responder!.perform(selector, with: url)
                break
            }
            responder = responder?.next
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.close()
        }
    }

    private func close() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
