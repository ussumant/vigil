import AppKit

enum VigilIconFactory {
    static func statusIcon(active: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        drawEye(
            in: NSRect(x: 1.5, y: 3.25, width: 13, height: 9.5),
            active: active,
            stroke: active ? DesignTokens.Color.accentEmber : DesignTokens.Color.ink400,
            lineWidth: 1.5
        )
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    static func drawEye(in rect: NSRect, active: Bool, stroke: NSColor, lineWidth: CGFloat) {
        stroke.setStroke()
        stroke.setFill()

        if active {
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

            let pupilRadius = max(1.2, irisRadius * 0.26)
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
        } else {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: rect.minX, y: rect.midY))
            path.curve(
                to: NSPoint(x: rect.maxX, y: rect.midY),
                controlPoint1: NSPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.22),
                controlPoint2: NSPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY + rect.height * 0.22)
            )
            path.lineWidth = lineWidth
            path.lineCapStyle = .round
            path.stroke()
        }
    }
}
