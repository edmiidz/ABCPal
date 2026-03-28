//
//  BookReaderView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct BookReaderView: View {
    var language: String
    var goBack: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        if let image = selectedImage {
            ImageReaderView(
                image: image,
                language: language,
                onDismiss: goBack,
                allowNewPhoto: true,
                onNewImage: { newImage in
                    selectedImage = newImage
                }
            )
            .id(image)
        } else {
            // Landing page: pick a photo or open camera
            VStack(spacing: 30) {
                // Back button
                HStack {
                    Button(action: {
                        synthesizer.stopSpeaking(at: .immediate)
                        goBack()
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward")
                            Text(language == "fr-CA" ? "Retour" : language == "ja-JP" ? "戻る" : "Back")
                        }
                        .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                Spacer()

                Image(systemName: "text.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.blue.opacity(0.6))

                Text(language == "fr-CA" ? "Choisissez une photo pour lire" : language == "ja-JP" ? "読む写真を選んでください" : "Choose a photo to read")
                    .font(.title2)
                    .multilineTextAlignment(.center)

                // Photo picker button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(language == "fr-CA" ? "Choisir une photo" : language == "ja-JP" ? "写真を選ぶ" : "Pick a Photo")
                    }
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                // Open camera app button
                Button(action: openCameraApp) {
                    HStack {
                        Image(systemName: "camera")
                        Text(language == "fr-CA" ? "Ouvrir l'appareil photo" : language == "ja-JP" ? "カメラを開く" : "Open Camera")
                    }
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                // Guidance text
                Text(language == "fr-CA" ? "Prenez une photo, recadrez-la,\npuis partagez-la dans ABCPal" : language == "ja-JP" ? "写真を撮って、トリミングして、\nABCPalに共有してください" : "Take a photo, crop it,\nthen share it back into ABCPal")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem = newItem else { return }
                newItem.loadTransferable(type: Data.self) { result in
                    DispatchQueue.main.async {
                        selectedPhotoItem = nil
                        if case .success(let data) = result,
                           let data = data,
                           let uiImage = UIImage(data: data) {
                            selectedImage = fixImageOrientation(uiImage)
                        }
                    }
                }
            }
        }
    }

    private func openCameraApp() {
        if let url = URL(string: "camera://") {
            UIApplication.shared.open(url)
        }
    }

    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalized
    }
}
