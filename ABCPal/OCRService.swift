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
        print("Starting OCR process on full image...")
        
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
            
            // Sort observations by vertical position (top to bottom)
            let sortedObservations = observations.sorted { (first, second) -> Bool in
                return first.boundingBox.midY > second.boundingBox.midY
            }
            
            // Convert observations to text
            let recognizedText = sortedObservations.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            print("OCR Result length: \(recognizedText.count) characters")
            completion(recognizedText)
        }
        
        // Configure for better accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "fr-FR"]  // Support both languages
        
        // Process the image
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error.localizedDescription)")
            completion(nil)
        }
    }
}