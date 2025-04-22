//
//  AboutView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/17/25.
//


//
//  AboutShareViews.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/17/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct AboutView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    isShowing = false
                }) {
                    HStack {
                        Image(systemName: "arrow.backward")
                        Text("Back")
                    }
                    .padding(8)
                    .foregroundColor(.blue)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Text("About ABCPal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Image("splashImage")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .padding()
            
            VStack(alignment: .leading, spacing: 15) {
                InfoRow(icon: "abc", title: "Purpose", content: "ABCPal helps children learn the alphabet in English and French")
                
                InfoRow(icon: "person.2.fill", title: "Target Audience", content: "Children ages 3-6 learning their letters")
                
                InfoRow(icon: "speaker.wave.3.fill", title: "Features", content: "Text-to-speech, interactive quizzes, and bilingual support")
                
                InfoRow(icon: "envelope.fill", title: "Support", content: "edmiidzapps@gmail.com")
                InfoRow(icon: "c.circle", title: "Copyright", content: "© 2025 Nik Edmiidz")
                
                InfoRow(icon: "1.circle", title: "Version", content: "1.0")
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct InfoRow: View {
    var icon: String
    var title: String
    var content: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ShareView: View {
    @Binding var isShowing: Bool
    @State private var showShareSheet = false
    let appURL = "https://apps.apple.com/app/id6744830469"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    isShowing = false
                }) {
                    HStack {
                        Image(systemName: "arrow.backward")
                        Text("Back")
                    }
                    .padding(8)
                    .foregroundColor(.blue)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Share ABCPal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Scan this QR code to download the app")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            QRCodeView(url: appURL)
                .frame(width: 200, height: 200)
                .padding()
            
            Text(appURL)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                showShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Link")
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Check out ABCPal, a fun app to help kids learn the alphabet!", URL(string: appURL)!])
        }
    }
}

// Helper ShareSheet struct that wraps UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Not needed
    }
}

struct QRCodeView: View {
    let url: String
    
    var body: some View {
        Image(uiImage: generateQRCode(from: url))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .background(Color.white)
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            let scale = UIScreen.main.scale
            let transform = CGAffineTransform(scaleX: scale * 10, y: scale * 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
