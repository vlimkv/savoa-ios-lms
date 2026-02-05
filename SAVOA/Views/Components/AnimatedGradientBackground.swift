//
//  AnimatedGradientBackground.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base black
            Color.black
            
            // Animated subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.05),
                    Color.clear,
                    Color.white.opacity(0.03),
                    Color.clear
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .blur(radius: 30)
            
            // Radial glow
            RadialGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}
