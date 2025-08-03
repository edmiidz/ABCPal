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
            var lineGroups: [[VNRecognizedTextObservation]] = []
            let sortedObservations = observations.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
            
            for observation in sortedObservations {
                var added = false
                for i in 0..<lineGroups.count {
                    if let firstInGroup = lineGroups[i].first {
                        // If Y positions are close (within 2% of image height), group them
                        if abs(firstInGroup.boundingBox.midY - observation.boundingBox.midY) < 0.02 {
                            lineGroups[i].append(observation)
                            lineGroups[i].sort { $0.boundingBox.minX < $1.boundingBox.minX }
                            added = true
                            break
                        }
                    }
                }
                if !added {
                    lineGroups.append([observation])
                }
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