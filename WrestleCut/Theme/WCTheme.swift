import SwiftUI

enum WCTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let surface2 = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let red = Color(red: 0.84, green: 0.08, blue: 0.14) // #D726...
    static let redBright = Color(red: 0.92, green: 0.10, blue: 0.18)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.17)
    static let goldDim = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.72)
    static let textTertiary = Color(white: 0.48)
    static let success = Color(red: 0.20, green: 0.78, blue: 0.45)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.12)
    static let corner: CGFloat = 20
    static let cornerSmall: CGFloat = 14
}

extension View {
    func wcCard() -> some View {
        self.padding(16)
            .background(WCTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: WCTheme.corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: WCTheme.corner, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
    func wcBackground() -> some View {
        self.background(WCTheme.background.ignoresSafeArea())
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
                Text(title).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(LinearGradient(colors: [WCTheme.redBright, WCTheme.red], startPoint: .topLeading, endPoint: .bottomTrailing))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityLabel(title)
    }
}

struct SectionHeader: View {
    var title: String; var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.weight(.black)).foregroundStyle(.white).textCase(.uppercase)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(WCTheme.textSecondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
