//
//  OCRService.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import Vision
import UIKit

class OCRService {
    func performOCR(on image: CGImage, language: String = "en-US", completion: @escaping (String?) -> Void) {
        print("Starting OCR process on image... language=\(language)")
        print("Image dimensions: \(image.width) x \(image.height)")

        if language == "ja-JP" {
            // Japanese OCR: try accurate first, fall back to fast
            performJapaneseOCR(on: image, completion: completion)
        } else {
            performStandardOCR(on: image, completion: completion)
        }
    }

    private func performJapaneseOCR(on image: CGImage, completion: @escaping (String?) -> Void) {
        // Strategy 1: Try original image with .accurate
        runOCR(on: image, languages: ["ja-JP"], level: .accurate) { result in
            if let text = result, !text.isEmpty {
                print("Japanese OCR succeeded with .accurate on original")
                completion(text)
                return
            }
            print("Japanese OCR .accurate failed on original")

            // Strategy 2: Enhance image — high contrast B&W with threshold binarization
            // This converts yellowed/sepia pages to clean black text on white
            if let enhanced = self.binarizeForOCR(image) {
                print("Trying OCR on binarized image")
                self.runOCR(on: enhanced, languages: ["ja-JP"], level: .accurate) { result in
                    if let text = result, !text.isEmpty {
                        print("Japanese OCR succeeded on binarized image")
                        completion(text)
                        return
                    }
                    print("Japanese OCR binarized also failed")

                    // Strategy 3: Try without specifying revision (use system default)
                    self.runOCRDefaultRevision(on: image, languages: ["ja-JP"]) { result in
                        if let text = result, !text.isEmpty {
                            print("Japanese OCR succeeded with default revision")
                            completion(text)
                            return
                        }
                        print("All Japanese OCR strategies failed")
                        completion(nil)
                    }
                }
            } else {
                print("Binarization failed, trying default revision")
                self.runOCRDefaultRevision(on: image, languages: ["ja-JP"]) { result in
                    completion(result)
                }
            }
        }
    }

    /// Binarize image: convert to high-contrast black text on white background
    private func binarizeForOCR(_ cgImage: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: cgImage)

        // Step 1: Convert to grayscale and boost contrast
        guard let colorControls = CIFilter(name: "CIColorControls") else { return nil }
        colorControls.setValue(ciImage, forKey: kCIInputImageKey)
        colorControls.setValue(0.0, forKey: kCIInputSaturationKey)  // Grayscale
        colorControls.setValue(2.0, forKey: kCIInputContrastKey)    // High contrast
        colorControls.setValue(0.0, forKey: kCIInputBrightnessKey)

        guard let grayImage = colorControls.outputImage else { return nil }

        // Step 2: Apply threshold to make it pure black and white
        // Using CIColorMatrix to push grays to black or white
        guard let clamp = CIFilter(name: "CIColorClamp") else {
            // Fallback: just return the high-contrast grayscale
            let context = CIContext()
            return context.createCGImage(grayImage, from: grayImage.extent)
        }
        clamp.setValue(grayImage, forKey: kCIInputImageKey)
        clamp.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputMinComponents")
        clamp.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")

        let finalImage = clamp.outputImage ?? grayImage
        let context = CIContext()
        return context.createCGImage(finalImage, from: finalImage.extent)
    }

    /// Run OCR without specifying a revision — lets the system choose the best available
    private func runOCRDefaultRevision(on image: CGImage, languages: [String], completion: @escaping (String?) -> Void) {
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("OCR Error (default revision): \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                print("Found 0 text observations (default revision)")
                completion(nil)
                return
            }
            print("Found \(observations.count) text observations (default revision)")
            let text = self.groupObservations(observations)
            completion(text.isEmpty ? nil : text)
        }

        // Don't set revision — let the system pick
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages
        request.customWords = []

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("OCR default revision failed: \(error.localizedDescription)")
            completion(nil)
        }
    }


    private func performStandardOCR(on image: CGImage, completion: @escaping (String?) -> Void) {
        runOCR(on: image, languages: ["en-US", "fr-FR"], level: .accurate, completion: completion)
    }

    private func runOCR(on image: CGImage, languages: [String], level: VNRequestTextRecognitionLevel, autoDetect: Bool = false, completion: @escaping (String?) -> Void) {
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text observations found")
                completion(nil)
                return
            }

            print("Found \(observations.count) text observations (level=\(level.rawValue), langs=\(languages))")

            if observations.isEmpty {
                completion(nil)
                return
            }

            let recognizedText = self.groupObservations(observations)

            print("OCR Result length: \(recognizedText.count) characters")
            print("First 100 chars: \(String(recognizedText.prefix(100)))")
            completion(recognizedText.isEmpty ? nil : recognizedText)
        }

        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLevel = level
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages
        request.automaticallyDetectsLanguage = autoDetect
        request.customWords = []

        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error.localizedDescription)")
            completion(nil)
        }
    }

    private func groupObservations(_ observations: [VNRecognizedTextObservation]) -> String {
        // Group observations by approximate Y position (for better line grouping)
        let avgHeight: CGFloat = observations.isEmpty ? 0.03 :
            observations.map { $0.boundingBox.height }.reduce(0, +) / CGFloat(observations.count)
        let groupingThreshold = max(avgHeight * 0.5, 0.02)

        var lineGroups: [[VNRecognizedTextObservation]] = []

        for observation in observations {
            var added = false
            for i in 0..<lineGroups.count {
                let groupMidY = lineGroups[i].map { $0.boundingBox.midY }.reduce(0, +) / CGFloat(lineGroups[i].count)
                if abs(groupMidY - observation.boundingBox.midY) < groupingThreshold {
                    lineGroups[i].append(observation)
                    added = true
                    break
                }
            }
            if !added {
                lineGroups.append([observation])
            }
        }

        // Sort groups top-to-bottom (Vision Y=0 is bottom, so descending midY = top first)
        lineGroups.sort { group1, group2 in
            let midY1 = group1.map { $0.boundingBox.midY }.reduce(0, +) / CGFloat(group1.count)
            let midY2 = group2.map { $0.boundingBox.midY }.reduce(0, +) / CGFloat(group2.count)
            return midY1 > midY2
        }
        for i in 0..<lineGroups.count {
            lineGroups[i].sort { $0.boundingBox.minX < $1.boundingBox.minX }
        }

        return lineGroups.map { group in
            group.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
        }.joined(separator: "\n")
    }
}