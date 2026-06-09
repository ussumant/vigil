import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let inputURL = root.appendingPathComponent("Assets/coffee-travel-cup-generated.png")
let alphaURL = root.appendingPathComponent("Assets/coffee-travel-cup-alpha.png")
let iconSourceURL = root.appendingPathComponent("Assets/AppIcon-1024.png")

guard let inputData = try? Data(contentsOf: inputURL),
      let sourceRep = NSBitmapImageRep(data: inputData) else {
    fatalError("Unable to read \(inputURL.path)")
}

let width = sourceRep.pixelsWide
let height = sourceRep.pixelsHigh

guard let alphaRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Unable to create alpha bitmap")
}

func clamp(_ value: CGFloat, _ minValue: CGFloat = 0, _ maxValue: CGFloat = 1) -> CGFloat {
    min(max(value, minValue), maxValue)
}

for y in 0..<height {
    for x in 0..<width {
        guard let color = sourceRep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
            continue
        }

        let red = color.redComponent
        let green = color.greenComponent
        let blue = color.blueComponent
        let dominantGreen = green - max(red, blue)
        let greenAmount = clamp((green - 0.36) / 0.48)
        let dominanceAmount = clamp((dominantGreen - 0.12) / 0.34)
        let keyAmount = clamp(greenAmount * dominanceAmount)
        let alpha = 1 - keyAmount

        let neutral = (red + blue) / 2
        let despilledGreen = min(green, neutral + 0.08)
        let output = NSColor(
            deviceRed: red,
            green: despilledGreen,
            blue: blue,
            alpha: alpha < 0.08 ? 0 : alpha
        )
        alphaRep.setColor(output, atX: x, y: y)
    }
}

guard let alphaData = alphaRep.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode alpha PNG")
}
try alphaData.write(to: alphaURL)

guard let cupImage = NSImage(contentsOf: alphaURL) else {
    fatalError("Unable to read extracted cup")
}

let iconSize = NSSize(width: 1024, height: 1024)
let iconImage = NSImage(size: iconSize)
iconImage.lockFocus()

NSColor.clear.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: iconSize)).fill()

let tileRect = NSRect(x: 56, y: 56, width: 912, height: 912)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
shadow.shadowBlurRadius = 28
shadow.shadowOffset = NSSize(width: 0, height: -14)
shadow.set()

let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: 208, yRadius: 208)
NSColor(calibratedRed: 0.94, green: 0.91, blue: 0.85, alpha: 1).setFill()
tilePath.fill()
NSGraphicsContext.restoreGraphicsState()

let highlightPath = NSBezierPath(roundedRect: tileRect.insetBy(dx: 22, dy: 22), xRadius: 188, yRadius: 188)
NSColor.white.withAlphaComponent(0.18).setStroke()
highlightPath.lineWidth = 3
highlightPath.stroke()

let cupRect = NSRect(x: 114, y: 94, width: 796, height: 796)
cupImage.draw(in: cupRect, from: .zero, operation: .sourceOver, fraction: 1)

iconImage.unlockFocus()

guard let tiffData = iconImage.tiffRepresentation,
      let outputRep = NSBitmapImageRep(data: tiffData),
      let outputData = outputRep.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon source PNG")
}

try outputData.write(to: iconSourceURL)
print("Wrote \(alphaURL.path)")
print("Wrote \(iconSourceURL.path)")
