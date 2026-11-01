import SwiftUI
import UIKit

/// Modern, clean palette — no neon, no glows, no glassy sci-fi gradients.
/// Dark: warm charcoal (#1C1C1E → #2A2A2D) with off-white text.
/// Light: soft cream with charcoal text. Accents in both modes:
/// deep wrestling red #B3262E and muted gold #C9A24B. System font (SF Pro) throughout.
private func dynamicColor(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
    Color(UIColor { traits in
        let c = traits.userInterfaceStyle == .light ? light : dark
        return UIColor(red: CGFloat(c.0), green: CGFloat(c.1), blue: CGFloat(c.2), alpha: 1)
    })
}

enum WCTheme {
    static let background = dynamicColor(light: (0.965, 0.941, 0.894), dark: (0.110, 0.110, 0.118)) // cream / #1C1C1E
    static let surface = dynamicColor(light: (1.0, 0.996, 0.980), dark: (0.145, 0.145, 0.157))       // near-white / #252528
    static let surface2 = dynamicColor(light: (0.929, 0.894, 0.827), dark: (0.165, 0.165, 0.176))      // sand / #2A2A2D
    static let red = Color(red: 0.702, green: 0.149, blue: 0.180)        // #B3262E
    static let redBright = Color(red: 0.780, green: 0.208, blue: 0.247)
    static let redDeep = Color(red: 0.545, green: 0.106, blue: 0.133)
    static let gold = Color(red: 0.788, green: 0.635, blue: 0.294)       // #C9A24B
    static let goldDim = Color(red: 0.639, green: 0.502, blue: 0.216)
    static let textPrimary = dynamicColor(light: (0.110, 0.110, 0.118), dark: (0.961, 0.949, 0.918))  // charcoal / off-white
    static let textSecondary = dynamicColor(light: (0.330, 0.325, 0.310), dark: (0.780, 0.770, 0.740))
    static let textTertiary = dynamicColor(light: (0.520, 0.510, 0.480), dark: (0.580, 0.570, 0.540))
    static let blue = Color(red: 0.55, green: 0.71, blue: 0.83) // muted steel blue — water only
    static let success = Color(red: 0.22, green: 0.62, blue: 0.38)
    static let warning = Color(red: 0.85, green: 0.55, blue: 0.16)
    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

/// Clean flat backdrop in the theme background color — no glows or gradients.
/// Rendered as a background, so it NEVER affects layout size.
struct WCBackdrop: View {
    var body: some View {
        WCTheme.background
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

extension View {
    func wcCard() -> some View {
        self.padding(16)
            .background(WCTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: WCTheme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WCTheme.corner, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
    }
    func wcBackground() -> some View {
        self.background(WCBackdrop())
    }
}

struct WCGradientButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.bold).lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 10)
            .background(WCTheme.red)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .accessibilityLabel(title)
    }
}

struct SectionHeader: View {
    var title: String; var subtitle: String? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(WCTheme.red)
                .frame(width: 4)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3.weight(.bold)).foregroundStyle(WCTheme.textPrimary).textCase(.uppercase)
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(WCTheme.textSecondary) }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Mini app-badge used in headers: red mat ring with a gold W. Fixed small size, layout-safe.
struct WCBadge: View {
    var size: CGFloat = 62
    var body: some View {
        ZStack {
            Circle().fill(WCTheme.surface2)
            Circle().stroke(WCTheme.red, lineWidth: size * 0.075)
            Circle().stroke(WCTheme.gold.opacity(0.55), lineWidth: 1.2).padding(size * 0.10)
            Text("W").font(.system(size: size * 0.52, weight: .black, design: .rounded)).foregroundStyle(WCTheme.gold)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}
