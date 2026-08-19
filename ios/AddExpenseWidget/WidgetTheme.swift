import SwiftUI

/// Mirrors the dark-theme values in `lib/config/design_tokens.dart`.
/// Swift can't import the Dart tokens directly, so the hex values are
/// duplicated here — keep in sync by hand if the app's dark palette changes.
enum WidgetTheme {
    static let background = Color(red: 0x00 / 255, green: 0x00 / 255, blue: 0x00 / 255)
    static let surface = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.3)
    static let border = Color.white.opacity(0.16)

    static let teal = Color(red: 0x00 / 255, green: 0xC8 / 255, blue: 0x96 / 255)
    static let success = Color(red: 0x34 / 255, green: 0xC7 / 255, blue: 0x59 / 255)
    static let secondary = Color(red: 0x0A / 255, green: 0x84 / 255, blue: 0xFF / 255)
}

/// A tap target used inside the Quick Actions widget: a tinted icon badge
/// over a label, wrapped in a `Link` so each column opens its own deep link.
struct WidgetActionButton: View {
    let icon: String
    let label: String
    let tint: Color
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(tint)
                }
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
