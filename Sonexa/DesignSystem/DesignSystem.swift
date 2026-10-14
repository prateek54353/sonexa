import SwiftUI

// MARK: - Typography
struct Typography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Colors
struct Colors {
    // Dark Theme (Default)
    static let background = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let secondaryBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let tertiaryBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let accent = Color(red: 0.0, green: 0.5, blue: 1.0)
    static let accentSecondary = Color(red: 0.3, green: 0.6, blue: 1.0)
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let success = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.0)
    
    // Light Theme
    static let lightBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let lightSecondaryBackground = Color.white
    static let lightPrimaryText = Color.black
    static let lightSecondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
}

// MARK: - Theme
enum AppTheme: String, CaseIterable {
    case dark
    case light
    
    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
}

// MARK: - Corner Radius
struct CornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14
    static let xl: CGFloat = 20
}

// MARK: - View Modifiers
struct StandardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Colors.tertiaryBackground)
            .foregroundColor(Colors.primaryText)
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Colors.secondaryBackground)
            .cornerRadius(CornerRadius.lg)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
}
