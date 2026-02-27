//
//  OCRService.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import Vision
import UIKit

class OCRService {
    func performOCR(on image: CGImage, completion: @escaping (String?) -> Void) {
        print("Starting OCR process on image...")
        print("Image dimensions: \(image.width) x \(image.height)")
        
        // Create a text recognition request
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Process the results
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text observations found")
                completion(nil)
                return
            }
            
            print("Found \(observations.count) text observations")
            
            // Group observations by approximate Y position (for better line grouping)
            // Use average bounding box height as a dynamic threshold so it adapts
            // to large-font children's books and small-font text alike.
            let avgHeight: CGFloat = observations.isEmpty ? 0.03 :
                observations.map { $0.boundingBox.height }.reduce(0, +) / CGFloat(observations.count)
            let groupingThreshold = max(avgHeight * 0.5, 0.02)

            var lineGroups: [[VNRecognizedTextObservation]] = []

            for observation in observations {
                var added = false
                for i in 0..<lineGroups.count {
                    // Compare against average midY of the group for stability
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
            // Then sort observations within each group left-to-right
            lineGroups.sort { group1, group2 in
                let midY1 = group1.map { $0.boundingBox.midY }.reduce(0, +) / CGFloat(group1.count)
                let midY2 = group2.map { $0.boundingBox.midY }.reduce(0, +) / CGFloat(group2.count)
                return midY1 > midY2
            }
            for i in 0..<lineGroups.count {
                lineGroups[i].sort { $0.boundingBox.minX < $1.boundingBox.minX }
            }

            // Convert grouped observations to text with proper spacing
            let recognizedText = lineGroups.map { group in
                group.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
            }.joined(separator: " ")
            
            print("OCR Result length: \(recognizedText.count) characters")
            print("First 100 chars: \(String(recognizedText.prefix(100)))")
            completion(recognizedText)
        }
        
        // Configure for maximum accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "fr-FR"]
        request.customWords = [] // Clear any custom words that might interfere
        
        // Create handler with preprocessing options
        let handler = VNImageRequestHandler(cgImage: image, options: [
            .ciContext: CIContext(options: [.useSoftwareRenderer: false])
        ])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error.localizedDescription)")
            completion(nil)
        }
    }
}