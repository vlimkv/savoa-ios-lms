//
//  SplashView.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.9
    
    var onComplete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeIn(duration: 0.3)) {
                    logoOpacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
