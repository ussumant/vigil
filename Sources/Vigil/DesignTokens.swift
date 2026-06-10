import AppKit

enum DesignTokens {
    enum Color {
        static let ink50 = NSColor(hex: 0xF3F5F8)
        static let ink100 = NSColor(hex: 0xE4E8EF)
        static let ink200 = NSColor(hex: 0xC5CDD9)
        static let ink300 = NSColor(hex: 0x9DA8BB)
        static let ink400 = NSColor(hex: 0x74819A)
        static let ink500 = NSColor(hex: 0x536075)
        static let ink600 = NSColor(hex: 0x3B4559)
        static let ink700 = NSColor(hex: 0x27303F)
        static let ink800 = NSColor(hex: 0x192030)
        static let ink900 = NSColor(hex: 0x111828)
        static let ink950 = NSColor(hex: 0x0A0F1A)

        static let surfacePage = NSColor(hex: 0x111828)
        static let surfaceRaised = NSColor(hex: 0x192030)
        static let surfaceSunken = NSColor(hex: 0x0A0F1A)
        static let surfaceInverse = NSColor(hex: 0xF3F5F8)

        static let textPrimary = NSColor(hex: 0xE8ECF2)
        static let textSecondary = NSColor(hex: 0x8A95A8)
        static let textTertiary = NSColor(hex: 0x4E5C72)
        static let textOnInverse = NSColor(hex: 0x111828)
        static let textLink = NSColor(hex: 0x7B9EE0)

        static let accentEmber = NSColor(hex: 0xE8982A)
        static let accentMist = NSColor(hex: 0x6B96D0)

        static let statusSuccess = NSColor(hex: 0x3D9B6A)
        static let statusWarning = NSColor(hex: 0xC97E2A)
        static let statusError = NSColor(hex: 0xC04848)
        static let statusInfo = NSColor(hex: 0x5B8EC2)
    }

    enum Space {
        static let x1: CGFloat = 4
        static let x2: CGFloat = 8
        static let x3: CGFloat = 12
        static let x4: CGFloat = 16
        static let x5: CGFloat = 20
        static let x6: CGFloat = 24
        static let x8: CGFloat = 32
        static let x10: CGFloat = 40
        static let x12: CGFloat = 48
        static let x16: CGFloat = 64
        static let x20: CGFloat = 80
        static let x24: CGFloat = 96
    }

    enum Radius {
        static let r2: CGFloat = 2
        static let r4: CGFloat = 4
        static let r6: CGFloat = 6
        static let r8: CGFloat = 8
        static let r12: CGFloat = 12
        static let r20: CGFloat = 20
    }

    enum Typography {
        static func displayHero() -> NSFont { FontBook.syne(size: 48, weight: .heavy) }
        static func displayTitle() -> NSFont { FontBook.syne(size: 28, weight: .bold) }
        static func displayEyebrow() -> NSFont { FontBook.syne(size: 13, weight: .semibold) }
        static func bodyDefault() -> NSFont { FontBook.inter(size: 16, weight: .regular) }
        static func bodySmall() -> NSFont { FontBook.inter(size: 14, weight: .regular) }
        static func uiLabel() -> NSFont { FontBook.inter(size: 13, weight: .medium) }
        static func uiCaption() -> NSFont { FontBook.inter(size: 11, weight: .regular) }
        static func codeDefault() -> NSFont { FontBook.jetBrainsMono(size: 14) }
        static func aboutVersion() -> NSFont { FontBook.jetBrainsMono(size: 12) }
    }
}

enum FontBook {
    static func syne(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        weightedFont(
            family: "Syne",
            names: names(for: "Syne", weight: weight),
            size: size,
            weight: weight
        )
    }

    static func inter(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        weightedFont(
            family: "Inter",
            names: names(for: "Inter", weight: weight),
            size: size,
            weight: weight
        )
    }

    static func jetBrainsMono(size: CGFloat) -> NSFont {
        namedFont(["JetBrainsMono-Regular", "JetBrains Mono"], size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    private static func weightedFont(
        family: String,
        names: [String],
        size: CGFloat,
        weight: NSFont.Weight
    ) -> NSFont {
        if let named = namedFont(names, size: size) {
            return named
        }

        let managerWeight = fontManagerWeight(for: weight)
        if let familyFont = NSFontManager.shared.font(
            withFamily: family,
            traits: [],
            weight: managerWeight,
            size: size
        ) {
            return familyFont
        }

        return NSFont.systemFont(ofSize: size, weight: weight)
    }

    private static func namedFont(_ names: [String], size: CGFloat) -> NSFont? {
        for name in names {
            if let font = NSFont(name: name, size: size) {
                return font
            }
        }
        return nil
    }

    private static func names(for family: String, weight: NSFont.Weight) -> [String] {
        switch weight {
        case .heavy:
            return ["\(family)-ExtraBold", family]
        case .bold:
            return ["\(family)-Bold", family]
        case .semibold:
            return ["\(family)-SemiBold", family]
        case .medium:
            return ["\(family)-Medium", family]
        default:
            return ["\(family)-Regular", family]
        }
    }

    private static func fontManagerWeight(for weight: NSFont.Weight) -> Int {
        switch weight {
        case .heavy:
            return 12
        case .bold:
            return 9
        case .semibold:
            return 8
        case .medium:
            return 6
        default:
            return 5
        }
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}
