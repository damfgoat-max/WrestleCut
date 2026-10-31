import SwiftUI

enum WCTheme {
    static let background = Color(red: 0.03, green: 0.03, blue: 0.04)
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let surface2 = Color(red: 0.14, green: 0.13, blue: 0.17)
    static let red = Color(red: 0.84, green: 0.08, blue: 0.14)
    static let redBright = Color(red: 0.93, green: 0.12, blue: 0.20)
    static let redDeep = Color(red: 0.42, green: 0.03, blue: 0.07)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.17)
    static let goldDim = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.74)
    static let textTertiary = Color(white: 0.50)
    static let success = Color(red: 0.20, green: 0.78, blue: 0.45)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.12)
    static let corner: CGFloat = 22
    static let cornerSmall: CGFloat = 14
}

/// Full-screen aesthetic backdrop: deep black with a soft red glow bleeding
/// from the top (like arena lights on a mat) and a faint gold warmth at the bottom.
/// Rendered as a background, so it NEVER affects layout size — content always fits the device screen exactly.
struct WCBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.02, blue: 0.03), WCTheme.background, Color(red: 0.05, green: 0.04, blue: 0.02)],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [WCTheme.red.opacity(0.22), .clear],
                center: .top, startRadius: 10, endRadius: 420
            )
            // Wrestling mat ring, purely decorative and clipped to the screen.
            Circle()
                .stroke(WCTheme.red.opacity(0.10), lineWidth: 26)
                .frame(width: 340, height: 340)
                .offset(y: -330)
        }
        .ignoresSafeArea()
        .clipped()
        .accessibilityHidden(true)
    }
}

extension View {
    func wcCard() -> some View {
        self.padding(16)
            .background(
                LinearGradient(colors: [WCTheme.surface2.opacity(0.55), WCTheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: WCTheme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WCTheme.corner, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.03), WCTheme.gold.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
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
            .background(LinearGradient(colors: [WCTheme.redBright, WCTheme.red, WCTheme.redDeep], startPoint: .top, endPoint: .bottom))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
            .shadow(color: WCTheme.red.opacity(0.45), radius: 10, x: 0, y: 5)
        }
        .accessibilityLabel(title)
    }
}

struct SectionHeader: View {
    var title: String; var subtitle: String? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(colors: [WCTheme.redBright, WCTheme.gold], startPoint: .top, endPoint: .bottom))
                .frame(width: 4)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3.weight(.black)).foregroundStyle(.white).textCase(.uppercase)
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
            Circle().fill(LinearGradient(colors: [WCTheme.surface2, WCTheme.background], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(WCTheme.red, lineWidth: size * 0.075)
            Circle().stroke(WCTheme.gold.opacity(0.55), lineWidth: 1.2).padding(size * 0.10)
            Text("W").font(.system(size: size * 0.52, weight: .black, design: .rounded)).foregroundStyle(LinearGradient(colors: [WCTheme.gold, WCTheme.goldDim], startPoint: .top, endPoint: .bottom))
        }
        .frame(width: size, height: size)
        .shadow(color: WCTheme.red.opacity(0.4), radius: 8, x: 0, y: 4)
        .accessibilityHidden(true)
    }
}
