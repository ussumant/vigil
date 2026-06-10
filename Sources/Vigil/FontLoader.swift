import AppKit
import CoreText

enum FontLoader {
    static func registerBundledFonts(bundle: Bundle = .main) {
        guard let fontsURL = bundle.resourceURL?.appendingPathComponent("Fonts", isDirectory: true),
              let fontURLs = try? FileManager.default.contentsOfDirectory(
                at: fontsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return
        }

        for fontURL in fontURLs where ["ttf", "otf"].contains(fontURL.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
