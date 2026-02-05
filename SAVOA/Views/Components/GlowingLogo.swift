//
//  GlowingLogo.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI

struct GlowingLogo: View {
    @State private var isGlowing = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Subtle rotating ring behind logo
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(rotationAngle))
                .opacity(0.6)
            
            // Your logo - will blend naturally
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: .white.opacity(0.2), radius: 30)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
            
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isGlowing = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        GlowingLogo()
    }
}
