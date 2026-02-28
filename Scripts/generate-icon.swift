#!/usr/bin/env swift

// Generates a macOS app icon for BrowserSchedule
// Renders a clock face with two colored arcs representing work/personal time splits,
// with a small globe overlay to convey "browser routing"

import AppKit
import Foundation

let iconsetPath = "Resources/AppIcon.iconset"

// macOS icon sizes: (filename, size in pixels)
let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard NSGraphicsContext.current?.cgContext != nil else {
        image.unlockFocus()
        return image
    }

    let s = size
    let inset = s * 0.08
    let cornerRadius = s * 0.22 // macOS squircle-ish

    // --- Background squircle with gradient ---
    let squircle = NSBezierPath(
        roundedRect: NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2),
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )

    // Gradient: deep blue to teal
    let gradient = NSGradient(
        starting: NSColor(red: 0.15, green: 0.25, blue: 0.65, alpha: 1.0),
        ending: NSColor(red: 0.20, green: 0.55, blue: 0.70, alpha: 1.0)
    )!
    gradient.draw(in: squircle, angle: -45)

    // Subtle inner shadow / border
    NSColor(white: 1.0, alpha: 0.12).setStroke()
    squircle.lineWidth = s * 0.01
    squircle.stroke()

    // --- Clock face ---
    let center = NSPoint(x: s / 2, y: s / 2)
    let clockRadius = s * 0.30

    // Clock circle background
    let clockBg = NSBezierPath(
        ovalIn: NSRect(
            x: center.x - clockRadius,
            y: center.y - clockRadius,
            width: clockRadius * 2,
            height: clockRadius * 2
        )
    )
    NSColor(white: 1.0, alpha: 0.15).setFill()
    clockBg.fill()

    // Clock ring
    NSColor(white: 1.0, alpha: 0.8).setStroke()
    clockBg.lineWidth = s * 0.02
    clockBg.stroke()

    // --- Work/personal arcs ---
    // Work arc (orange) — roughly 9:00 to 18:00 (top-right to bottom-right, 270° worth)
    let arcRadius = clockRadius * 0.85
    let workArc = NSBezierPath()
    // In CG coordinates: 0° is right, 90° is up
    // 9:00 on clock = 90° in CG (12 o'clock) going clockwise to 6:00 = 270° (6 o'clock)
    // That's 9 hours out of 12 on a clock face, but we want to show work hours
    // Work: 9am-6pm = 9 hours. Personal: 6pm-9am = 15 hours
    // On a 24hr basis: work = 37.5% of day, personal = 62.5%
    // Let's use a simpler visual: work arc from ~1 o'clock to ~7 o'clock position
    workArc.appendArc(
        withCenter: center,
        radius: arcRadius,
        startAngle: 60,   // ~2 o'clock
        endAngle: -90,    // ~6 o'clock
        clockwise: true
    )
    NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.9).setStroke()
    workArc.lineWidth = s * 0.035
    workArc.lineCapStyle = .round
    workArc.stroke()

    // Personal arc (green) — the rest
    let personalArc = NSBezierPath()
    personalArc.appendArc(
        withCenter: center,
        radius: arcRadius,
        startAngle: -90,
        endAngle: 60,
        clockwise: true
    )
    NSColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 0.9).setStroke()
    personalArc.lineWidth = s * 0.035
    personalArc.lineCapStyle = .round
    personalArc.stroke()

    // --- Clock hands ---
    NSColor(white: 1.0, alpha: 0.95).setStroke()

    // Hour hand (pointing to ~10 o'clock)
    let hourAngle = CGFloat.pi * 2 * (10.0 / 12.0) - .pi / 2
    let hourLength = clockRadius * 0.5
    let hourHand = NSBezierPath()
    hourHand.move(to: center)
    hourHand.line(
        to: NSPoint(
            x: center.x + cos(hourAngle) * hourLength,
            y: center.y + sin(hourAngle) * hourLength
        )
    )
    hourHand.lineWidth = s * 0.025
    hourHand.lineCapStyle = .round
    hourHand.stroke()

    // Minute hand (pointing to ~12 o'clock)
    let minuteAngle = CGFloat.pi / 2 // straight up
    let minuteLength = clockRadius * 0.7
    let minuteHand = NSBezierPath()
    minuteHand.move(to: center)
    minuteHand.line(
        to: NSPoint(
            x: center.x + cos(minuteAngle) * minuteLength,
            y: center.y + sin(minuteAngle) * minuteLength
        )
    )
    minuteHand.lineWidth = s * 0.018
    minuteHand.lineCapStyle = .round
    minuteHand.stroke()

    // Center dot
    let dotRadius = s * 0.02
    let centerDot = NSBezierPath(
        ovalIn: NSRect(
            x: center.x - dotRadius,
            y: center.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
    )
    NSColor.white.setFill()
    centerDot.fill()

    // --- Hour markers (12 small ticks) ---
    for i in 0..<12 {
        let angle = CGFloat.pi * 2 * CGFloat(i) / 12.0 - .pi / 2
        let outerR = clockRadius * 0.95
        let innerR = (i % 3 == 0) ? clockRadius * 0.80 : clockRadius * 0.87
        let tick = NSBezierPath()
        tick.move(
            to: NSPoint(
                x: center.x + cos(angle) * innerR,
                y: center.y + sin(angle) * innerR
            )
        )
        tick.line(
            to: NSPoint(
                x: center.x + cos(angle) * outerR,
                y: center.y + sin(angle) * outerR
            )
        )
        NSColor(white: 1.0, alpha: 0.6).setStroke()
        tick.lineWidth = (i % 3 == 0) ? s * 0.015 : s * 0.008
        tick.lineCapStyle = .round
        tick.stroke()
    }

    // --- Small globe icon in bottom-right corner ---
    let globeSize = s * 0.22
    let globeCenter = NSPoint(
        x: s * 0.73,
        y: s * 0.27
    )

    // Globe background circle
    let globeBg = NSBezierPath(
        ovalIn: NSRect(
            x: globeCenter.x - globeSize / 2,
            y: globeCenter.y - globeSize / 2,
            width: globeSize,
            height: globeSize
        )
    )
    NSColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 0.95).setFill()
    globeBg.fill()
    NSColor(white: 1.0, alpha: 0.5).setStroke()
    globeBg.lineWidth = s * 0.01
    globeBg.stroke()

    // Globe lines
    let globeStrokeColor = NSColor(white: 1.0, alpha: 0.7)
    globeStrokeColor.setStroke()

    // Horizontal line
    let hLine = NSBezierPath()
    hLine.move(to: NSPoint(x: globeCenter.x - globeSize * 0.4, y: globeCenter.y))
    hLine.line(to: NSPoint(x: globeCenter.x + globeSize * 0.4, y: globeCenter.y))
    hLine.lineWidth = s * 0.008
    hLine.stroke()

    // Vertical ellipse (meridian)
    let meridian = NSBezierPath(
        ovalIn: NSRect(
            x: globeCenter.x - globeSize * 0.2,
            y: globeCenter.y - globeSize * 0.38,
            width: globeSize * 0.4,
            height: globeSize * 0.76
        )
    )
    meridian.lineWidth = s * 0.008
    meridian.stroke()

    // Vertical line through center
    let vLine = NSBezierPath()
    vLine.move(to: NSPoint(x: globeCenter.x, y: globeCenter.y - globeSize * 0.4))
    vLine.line(to: NSPoint(x: globeCenter.x, y: globeCenter.y + globeSize * 0.4))
    vLine.lineWidth = s * 0.008
    vLine.stroke()

    image.unlockFocus()
    return image
}

// Create output directory
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Render all sizes
for (name, size) in sizes {
    let image = renderIcon(size: size)
    guard let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        print("Failed to render \(name)")
        continue
    }
    let path = "\(iconsetPath)/\(name).png"
    try png.write(to: URL(fileURLWithPath: path))
    print("Generated \(name).png (\(Int(size))x\(Int(size)))")
}

print("\nNow run: iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns")
