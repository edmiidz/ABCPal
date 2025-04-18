//
//  SlashView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool

    var body: some View {
        VStack {
            Image("splashImage")
                .resizable()
                .scaledToFit()
                .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // Optional background color
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}
