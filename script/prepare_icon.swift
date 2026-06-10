import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconSourceURL = root.appendingPathComponent("Assets/AppIcon-1024.png")

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func drawEye(in rect: NSRect, stroke: NSColor, lineWidth: CGFloat) {
    stroke.setStroke()
    stroke.setFill()

    let path = NSBezierPath()
    path.move(to: NSPoint(x: rect.minX, y: rect.midY))
    path.curve(
        to: NSPoint(x: rect.maxX, y: rect.midY),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY),
        controlPoint2: NSPoint(x: rect.maxX - rect.width * 0.24, y: rect.maxY)
    )
    path.curve(
        to: NSPoint(x: rect.minX, y: rect.midY),
        controlPoint1: NSPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.24, y: rect.minY)
    )
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()

    let irisRadius = min(rect.width, rect.height) * 0.22
    let irisRect = NSRect(
        x: rect.midX - irisRadius,
        y: rect.midY - irisRadius,
        width: irisRadius * 2,
        height: irisRadius * 2
    )
    let iris = NSBezierPath(ovalIn: irisRect)
    iris.lineWidth = lineWidth
    iris.stroke()

    let pupilRadius = irisRadius * 0.24
    NSBezierPath(
        ovalIn: NSRect(
            x: rect.midX - pupilRadius,
            y: rect.midY - pupilRadius,
            width: pupilRadius * 2,
            height: pupilRadius * 2
        )
    ).fill()

    let tickInset = irisRadius * 0.22
    let tickLength = irisRadius * 0.55
    let leftTick = NSBezierPath()
    leftTick.move(to: NSPoint(x: irisRect.minX - tickLength, y: rect.midY))
    leftTick.line(to: NSPoint(x: irisRect.minX - tickInset, y: rect.midY))
    leftTick.lineWidth = lineWidth
    leftTick.lineCapStyle = .round
    leftTick.stroke()

    let rightTick = NSBezierPath()
    rightTick.move(to: NSPoint(x: irisRect.maxX + tickInset, y: rect.midY))
    rightTick.line(to: NSPoint(x: irisRect.maxX + tickLength, y: rect.midY))
    rightTick.lineWidth = lineWidth
    rightTick.lineCapStyle = .round
    rightTick.stroke()
}

let iconSize = NSSize(width: 1024, height: 1024)
let iconImage = NSImage(size: iconSize)
iconImage.lockFocus()

NSColor.clear.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: iconSize)).fill()

let tileRect = NSRect(x: 56, y: 56, width: 912, height: 912)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
shadow.shadowBlurRadius = 34
shadow.shadowOffset = NSSize(width: 0, height: -18)
shadow.set()

let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: 208, yRadius: 208)
color(0x111828).setFill()
tilePath.fill()
NSGraphicsContext.restoreGraphicsState()

let raisedRect = tileRect.insetBy(dx: 36, dy: 36)
let raisedPath = NSBezierPath(roundedRect: raisedRect, xRadius: 176, yRadius: 176)
color(0x192030).setFill()
raisedPath.fill()

color(0x27303F).setStroke()
raisedPath.lineWidth = 3
raisedPath.stroke()

let bloom = NSGradient(colors: [
    color(0xE8982A, alpha: 0.32),
    color(0xE8982A, alpha: 0.08),
    color(0xE8982A, alpha: 0)
])!
bloom.draw(
    in: NSBezierPath(ovalIn: NSRect(x: 136, y: 120, width: 420, height: 260)),
    relativeCenterPosition: NSPoint(x: -0.25, y: -0.1)
)

drawEye(
    in: NSRect(x: 214, y: 356, width: 596, height: 312),
    stroke: color(0xE8982A),
    lineWidth: 34
)

iconImage.unlockFocus()

guard let tiffData = iconImage.tiffRepresentation,
      let outputRep = NSBitmapImageRep(data: tiffData),
      let outputData = outputRep.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon source PNG")
}

try outputData.write(to: iconSourceURL)
print("Wrote \(iconSourceURL.path)")
