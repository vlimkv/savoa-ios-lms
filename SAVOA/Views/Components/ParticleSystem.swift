//
//  ParticleSystem.swift
//  PelvicFloorApp
//
//  Created by 7Я on 04.12.2025.
//

import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
    var speed: Double
}

struct ParticleSystemView: View {
    @State private var particles: [Particle] = []
    let particleCount = 20
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white.opacity(particle.opacity))
                        .frame(width: 4, height: 4)
                        .scaleEffect(particle.scale)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startAnimation(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                opacity: Double.random(in: 0.1...0.3),
                scale: CGFloat.random(in: 0.5...1.5),
                speed: Double.random(in: 20...40)
            )
        }
    }
    
    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].y -= particles[i].speed * 0.05
                
                // Reset particle when it goes off screen
                if particles[i].y < -10 {
                    particles[i].y = size.height + 10
                    particles[i].x = CGFloat.random(in: 0...size.width)
                    particles[i].opacity = Double.random(in: 0.1...0.3)
                }
            }
        }
    }
}
