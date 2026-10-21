//
//  SplashView.swift
//  Paw Sitters
//
//  Animated launch screen: a trail of paw prints walks up to the logo,
//  which pops in with a beating heart, followed by the app name.
//

import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var visiblePaws = 0
    @State private var logoScale: CGFloat = 0.2
    @State private var logoOpacity = 0.0
    @State private var logoRotation = -20.0
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = 24
    @State private var heartBeat = false

    private let theme = AppTheme.current
    /// Paw positions as fractions of the screen, walking from bottom-left towards the logo.
    private let pawTrail: [(x: CGFloat, y: CGFloat, angle: Double)] = [
        (0.10, 0.95, 40), (0.20, 0.91, 55), (0.26, 0.85, 40), (0.36, 0.82, 60),
        (0.42, 0.76, 45), (0.52, 0.74, 70), (0.58, 0.69, 55), (0.50, 0.50, 0)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PawPatternBackground(symbolColor: .white.opacity(0.08), backgroundColor: theme.primary)

                ForEach(pawTrail.indices.dropLast(), id: \.self) { index in
                    let step = pawTrail[index]
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.45))
                        .rotationEffect(.degrees(step.angle))
                        .scaleEffect(index < visiblePaws ? 1 : 0.3)
                        .opacity(index < visiblePaws ? 1 : 0)
                        .position(x: step.x * geometry.size.width, y: step.y * geometry.size.height)
                }

                VStack(spacing: 20) {
                    ZStack {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 3)
                            .scaleEffect(heartBeat ? 1.25 : 0.9)
                            .offset(x: 62, y: -62)
                    }
                    .scaleEffect(logoScale)
                    .rotationEffect(.degrees(logoRotation))
                    .opacity(logoOpacity)

                    VStack(spacing: 6) {
                        Text("Paw Sitters")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                        Text("Trusted care for your furry friends")
                            .font(.system(.subheadline, design: .rounded))
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                }
            }
        }
        .ignoresSafeArea()
        .task { await runAnimation() }
    }

    @MainActor
    private func runAnimation() async {
        for index in 0..<(pawTrail.count - 1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                visiblePaws = index + 1
            }
            try? await Task.sleep(for: .milliseconds(110))
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
            logoScale = 1
            logoOpacity = 1
            logoRotation = 0
        }
        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(0.3)) {
            heartBeat = true
        }
        try? await Task.sleep(for: .milliseconds(350))
        withAnimation(.easeOut(duration: 0.5)) {
            titleOpacity = 1
            titleOffset = 0
        }
        try? await Task.sleep(for: .milliseconds(1300))
        onFinished()
    }
}

#Preview {
    SplashView { }
}
