//
//  SimpleLoadingIndicator.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import SwiftUI

struct SimpleLoadingIndicator: View {
    let size: CGFloat
    let color: Color
    
    @State private var isAnimating = false
    
    init(size: CGFloat = 20, color: Color = .blue) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1)
                .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

struct PulsingDot: View {
    let color: Color
    let size: CGFloat
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    init(color: Color = .blue, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
                value: scale
            )
            .onAppear {
                scale = 1.5
                opacity = 0.5
            }
    }
}

struct ThreeDotsLoading: View {
    let color: Color
    let size: CGFloat
    
    @State private var animationStates = [false, false, false]
    
    init(color: Color = .blue, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .scaleEffect(animationStates[index] ? 1.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationStates[index]
                    )
            }
        }
        .onAppear {
            for i in 0..<3 {
                animationStates[i] = true
            }
        }
    }
}

// MARK: - View Extensions for convenient loading states

extension View {
    func overlayLoading(_ isLoading: Bool, style: LoadingStyle = .spinner) -> some View {
        overlay(
            Group {
                if isLoading {
                    switch style {
                    case .spinner:
                        SimpleLoadingIndicator(size: 20, color: .white)
                    case .dots:
                        ThreeDotsLoading(color: .white, size: 6)
                    case .pulse:
                        PulsingDot(color: .white, size: 12)
                    }
                }
            }
        )
    }
}

enum LoadingStyle {
    case spinner
    case dots
    case pulse
}

#Preview {
    VStack(spacing: 30) {
        Text("loading_indicators".localized)
            .font(.title)
        
        HStack(spacing: 30) {
            VStack {
                SimpleLoadingIndicator()
                Text("spinner".localized)
                    .font(.caption)
            }
            
            VStack {
                ThreeDotsLoading()
                Text("three_dots".localized)
                    .font(.caption)
            }
            
            VStack {
                PulsingDot()
                Text("pulsing_dot".localized)
                    .font(.caption)
            }
        }
        
        Divider()
        
        VStack(spacing: 20) {
            Button("loading_button".localized) {}
                .buttonStyle(.borderedProminent)
                .overlayLoading(true, style: .spinner)
            
            Button("dots_loading".localized) {}
                .buttonStyle(.bordered)
                .overlayLoading(true, style: .dots)
        }
    }
    .padding()
}
