//
//  LoadingView.swift
//  PlateFinder
//
//  Created by Andres Sanchez on 05/07/2025.
//

import SwiftUI

struct LoadingView: View {
    @State private var animationAmount = 0.0
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated car icon
            VStack(spacing: 20) {
                Image(systemName: "car.2")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(animationAmount))
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: animationAmount
                    )
                
                Text("searching_information".localized)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("consulting_ant_database".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Skeleton loading cards
            VStack(spacing: 16) {
                SkeletonCarDetailCard()
                SkeletonCarDetailCard()
                SkeletonCarDetailCard()
                SkeletonCarDetailCard()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            animationAmount = 10.0
        }
    }
}

// MARK: - Skeleton Loading Components

struct SkeletonCarDetailCard: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity * 0.7)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity * 0.5)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .overlay(
            // Shimmer effect
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
                .clipped()
        )
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Loading State Modifier

struct LoadingStateModifier: ViewModifier {
    let isLoading: Bool
    let loadingMessage: String
    
    init(isLoading: Bool, message: String = "loading".localized) {
        self.isLoading = isLoading
        self.loadingMessage = message
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isLoading ? 2 : 0)
                .disabled(isLoading)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                    
                    Text(loadingMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "loading".localized) -> some View {
        modifier(LoadingStateModifier(isLoading: isLoading, message: message))
    }
}

#Preview {
    VStack {
        LoadingView()
        
        Divider()
            .padding()
        
        VStack {
            Text("sample_content".localized)
                .font(.title)
            
            Button("toggle_loading".localized) {}
                .buttonStyle(.bordered)
        }
        .loadingOverlay(isLoading: true, message: "processing_data".localized)
    }
}
