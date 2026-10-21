//
//  Theme.swift
//  Paw Sitters
//
//  App-wide colors and the animal-pattern background.
//  To switch the whole app to another palette, change `AppTheme.current`.
//

import SwiftUI

struct AppTheme {
    let name: String
    /// Main brand color: buttons, tab bar accent, splash background.
    let primary: Color
    /// Soft tint of the primary color: chips, secondary buttons.
    let secondary: Color
    /// Screen background behind the animal pattern.
    let background: Color
    /// Highlight color: favorites, badges, the "create" button.
    let accent: Color
    /// Text on light surfaces.
    let text: Color

    static let current = AppTheme.forest

    static let forest = AppTheme(name: "Orman Patisi",
                                 primary: Color(hex: 0x2F6B4F), secondary: Color(hex: 0xA8C3A0),
                                 background: Color(hex: 0xF6F1E7), accent: Color(hex: 0xE8873A),
                                 text: Color(hex: 0x1F3A2C))
    static let sunsetCoral = AppTheme(name: "Gün Batımı Mercan",
                                      primary: Color(hex: 0xE8735A), secondary: Color(hex: 0xF7C6A3),
                                      background: Color(hex: 0xFFF6EE), accent: Color(hex: 0x5A3A2E),
                                      text: Color(hex: 0x4A2C22))
    static let ocean = AppTheme(name: "Okyanus",
                                primary: Color(hex: 0x1E7A8C), secondary: Color(hex: 0x9AD3DE),
                                background: Color(hex: 0xF4EFE6), accent: Color(hex: 0xF2B544),
                                text: Color(hex: 0x123F49))
    static let lavender = AppTheme(name: "Lavanta Kedi",
                                   primary: Color(hex: 0x6E5BC4), secondary: Color(hex: 0xCFC6F2),
                                   background: Color(hex: 0xF8F6FD), accent: Color(hex: 0x5CC8A8),
                                   text: Color(hex: 0x2E2560))
    static let honeyCocoa = AppTheme(name: "Bal ve Kakao",
                                     primary: Color(hex: 0xE3A33B), secondary: Color(hex: 0xF6DDB0),
                                     background: Color(hex: 0xFFFAF0), accent: Color(hex: 0x5B3A29),
                                     text: Color(hex: 0x3F281C))
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Theme background with a faint, scattered pattern of animal symbols.
struct PawPatternBackground: View {
    var spacing: CGFloat = 64
    var symbolColor: Color = AppTheme.current.primary.opacity(0.09)
    var backgroundColor: Color = AppTheme.current.background

    private let symbols = ["pawprint.fill", "dog.fill", "cat.fill", "bird.fill",
                           "pawprint.fill", "hare.fill", "fish.fill", "tortoise.fill"]

    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2
            for row in 0..<rows {
                for column in 0..<columns {
                    let index = (row * 3 + column * 5) % symbols.count
                    guard let symbol = context.resolveSymbol(id: index) else { continue }
                    // Offset every other row so the pattern looks scattered rather than gridded.
                    let x = CGFloat(column) * spacing + (row.isMultiple(of: 2) ? spacing / 2 : 0)
                    let y = CGFloat(row) * spacing
                    var cell = context
                    cell.translateBy(x: x, y: y)
                    cell.rotate(by: .degrees(Double((row * 7 + column * 13) % 5 - 2) * 14))
                    cell.draw(symbol, at: .zero)
                }
            }
        } symbols: {
            ForEach(symbols.indices, id: \.self) { index in
                Image(systemName: symbols[index])
                    .font(.system(size: 20))
                    .foregroundStyle(symbolColor)
                    .tag(index)
            }
        }
        .background(backgroundColor)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Places the themed animal-pattern background behind the view.
    func pawBackground() -> some View {
        background(PawPatternBackground())
    }

    /// Filled, rounded button style in the theme's primary (or given) color.
    func themedButton(_ color: Color = AppTheme.current.primary) -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: 320)
            .background(color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: color.opacity(0.3), radius: 6, y: 3)
    }

    /// White rounded card used on top of the pattern background.
    func themedCard() -> some View {
        self
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }
}

/// Rounded text field with a leading icon, used on the auth screens.
struct ThemedTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.current.primary)
                .frame(width: 20)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .foregroundStyle(AppTheme.current.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.current.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.current.secondary.opacity(0.6), lineWidth: 1)
        )
    }
}

/// Centered screen title with a small icon, used at the top of each tab.
struct ScreenTitle: View {
    let title: String
    var icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.current.accent)
            }
            Text(title)
                .foregroundStyle(AppTheme.current.text)
        }
        .font(.system(.title3, design: .rounded).weight(.bold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

/// Friendly empty-state placeholder with an animal icon.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.current.primary)
                .frame(width: 96, height: 96)
                .background(AppTheme.current.secondary.opacity(0.45), in: Circle())
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.current.text)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.current.text.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
