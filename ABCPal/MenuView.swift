//
//  MenuView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/17/25.
//


//
//  MenuView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/17/25.
//

import SwiftUI

struct MenuView: View {
    @Binding var isShowing: Bool
    @Binding var showingAbout: Bool
    @Binding var showingShare: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 20)
            }
            
            Button(action: {
                isShowing = false
                showingAbout = true
            }) {
                HStack {
                    Image(systemName: "info.circle")
                        .frame(width: 24, height: 24)
                    Text("About ABCPal")
                        .font(.title3)
                }
                .foregroundColor(.primary)
            }
            
            Button(action: {
                isShowing = false
                showingShare = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 24, height: 24)
                    Text("Share App")
                        .font(.title3)
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }
}
