#!/usr/bin/env swift

// Generates a macOS app icon for BrowserSchedule
// Cyberpunk globe-clock — neon wireframe on dark void

import AppKit
import Foundation

let iconsetPath = "Resources/AppIcon.iconset"

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

// Neon glow helper — draws a path multiple times with increasing blur
func drawNeonGlow(ctx: CGContext, path: NSBezierPath, color: NSColor, glowRadius: CGFloat, coreWidth: CGFloat) {
    // Outer glow (wide, faint)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: glowRadius, color: color.withAlphaComponent(0.6).cgColor)
    color.withAlphaComponent(0.3).setStroke()
    path.lineWidth = coreWidth * 2.5
    path.stroke()
    ctx.restoreGState()

    // Inner glow (tighter)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: glowRadius * 0.4, color: color.withAlphaComponent(0.8).cgColor)
    color.withAlphaComponent(0.7).setStroke()
    path.lineWidth = coreWidth * 1.4
    path.stroke()
    ctx.restoreGState()

    // Core line (bright)
    color.withAlphaComponent(0.95).setStroke()
    path.lineWidth = coreWidth
    path.stroke()
}

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size
    let inset = s * 0.08
    let cornerRadius = s * 0.22
    let glowSize = s * 0.015

    // --- Background: near-black with deep purple ---
    let squircle = NSBezierPath(
        roundedRect: NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2),
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )
    let bgGrad = NSGradient(
        colorsAndLocations:
            (NSColor(red: 0.04, green: 0.02, blue: 0.10, alpha: 1.0), 0.0),
            (NSColor(red: 0.06, green: 0.04, blue: 0.14, alpha: 1.0), 0.5),
            (NSColor(red: 0.03, green: 0.02, blue: 0.08, alpha: 1.0), 1.0)
    )!
    bgGrad.draw(in: squircle, angle: -45)

    // Subtle border glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: s * 0.01, color: NSColor(red: 0.4, green: 0.0, blue: 0.8, alpha: 0.3).cgColor)
    NSColor(red: 0.3, green: 0.1, blue: 0.5, alpha: 0.25).setStroke()
    squircle.lineWidth = s * 0.008
    squircle.stroke()
    ctx.restoreGState()

    // --- Neon colors ---
    let neonCyan = NSColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 1.0)
    let neonMagenta = NSColor(red: 0.95, green: 0.15, blue: 0.60, alpha: 1.0)
    let neonPurple = NSColor(red: 0.60, green: 0.20, blue: 0.95, alpha: 1.0)

    // --- Globe ---
    let center = NSPoint(x: s / 2, y: s / 2)
    let globeR = s * 0.32

    let globePath = NSBezierPath(ovalIn: NSRect(
        x: center.x - globeR,
        y: center.y - globeR,
        width: globeR * 2,
        height: globeR * 2
    ))

    // Globe fill: very dark with subtle color
    let globeGrad = NSGradient(
        colorsAndLocations:
            (NSColor(red: 0.06, green: 0.08, blue: 0.18, alpha: 1.0), 0.0),
            (NSColor(red: 0.03, green: 0.04, blue: 0.12, alpha: 1.0), 0.6),
            (NSColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0), 1.0)
    )!
    globeGrad.draw(in: globePath, angle: 70)

    // Clip wireframe to globe
    ctx.saveGState()
    globePath.addClip()

    let wireColor = neonCyan.withAlphaComponent(0.30)
    let wireW = s * 0.005

    // Equator
    let equator = NSBezierPath()
    equator.move(to: NSPoint(x: center.x - globeR, y: center.y))
    equator.line(to: NSPoint(x: center.x + globeR, y: center.y))
    wireColor.setStroke()
    equator.lineWidth = wireW
    equator.stroke()

    // Latitude lines
    for yOff: CGFloat in [-0.55, -0.28, 0.28, 0.55] {
        let lat = NSBezierPath()
        lat.move(to: NSPoint(x: center.x - globeR, y: center.y + globeR * yOff))
        lat.line(to: NSPoint(x: center.x + globeR, y: center.y + globeR * yOff))
        wireColor.setStroke()
        lat.lineWidth = wireW
        lat.stroke()
    }

    // Prime meridian
    let pm = NSBezierPath()
    pm.move(to: NSPoint(x: center.x, y: center.y - globeR))
    pm.line(to: NSPoint(x: center.x, y: center.y + globeR))
    wireColor.setStroke()
    pm.lineWidth = wireW
    pm.stroke()

    // Meridian ellipses
    for xFactor: CGFloat in [0.25, 0.50, 0.75] {
        let m = NSBezierPath(ovalIn: NSRect(
            x: center.x - globeR * xFactor,
            y: center.y - globeR,
            width: globeR * xFactor * 2,
            height: globeR * 2
        ))
        wireColor.setStroke()
        m.lineWidth = wireW
        m.stroke()
    }

    // Subtle cyan ambient glow inside globe
    let ambientCenter = NSPoint(x: center.x, y: center.y)
    let ambient = NSGradient(
        colorsAndLocations:
            (neonCyan.withAlphaComponent(0.08), 0.0),
            (neonCyan.withAlphaComponent(0.0), 1.0)
    )!
    ambient.draw(fromCenter: ambientCenter, radius: 0, toCenter: ambientCenter, radius: globeR, options: [])

    ctx.restoreGState()

    // Globe border ring — neon cyan glow
    let ringPath = NSBezierPath(ovalIn: NSRect(
        x: center.x - globeR,
        y: center.y - globeR,
        width: globeR * 2,
        height: globeR * 2
    ))
    ringPath.lineCapStyle = .round
    drawNeonGlow(ctx: ctx, path: ringPath, color: neonCyan, glowRadius: glowSize * 1.5, coreWidth: s * 0.012)

    // --- Work/personal arcs ---
    let arcRadius = globeR + s * 0.045

    // Work arc — neon magenta
    let workArc = NSBezierPath()
    workArc.appendArc(
        withCenter: center,
        radius: arcRadius,
        startAngle: 60,
        endAngle: -90,
        clockwise: true
    )
    workArc.lineCapStyle = .round
    drawNeonGlow(ctx: ctx, path: workArc, color: neonMagenta, glowRadius: glowSize * 1.2, coreWidth: s * 0.018)

    // Personal arc — neon cyan
    let personalArc = NSBezierPath()
    personalArc.appendArc(
        withCenter: center,
        radius: arcRadius,
        startAngle: -90,
        endAngle: 60,
        clockwise: true
    )
    personalArc.lineCapStyle = .round
    drawNeonGlow(ctx: ctx, path: personalArc, color: neonCyan, glowRadius: glowSize * 1.2, coreWidth: s * 0.018)

    // --- Hour tick marks ---
    for i in 0..<12 {
        let angle = CGFloat.pi * 2 * CGFloat(i) / 12.0 - .pi / 2
        let outerR = arcRadius + s * 0.028
        let innerR = (i % 3 == 0) ? arcRadius - s * 0.008 : arcRadius + s * 0.008
        let tick = NSBezierPath()
        tick.move(to: NSPoint(
            x: center.x + cos(angle) * innerR,
            y: center.y + sin(angle) * innerR
        ))
        tick.line(to: NSPoint(
            x: center.x + cos(angle) * outerR,
            y: center.y + sin(angle) * outerR
        ))
        tick.lineCapStyle = .round
        let tickColor = (i % 3 == 0) ? neonPurple : neonCyan.withAlphaComponent(0.5)
        let tickWidth = (i % 3 == 0) ? s * 0.012 : s * 0.006
        drawNeonGlow(ctx: ctx, path: tick, color: tickColor, glowRadius: glowSize * 0.6, coreWidth: tickWidth)
    }

    // --- Clock hands ---
    // Hour hand (~10 o'clock)
    let hourAngle = CGFloat.pi * 2 * (10.0 / 12.0) - .pi / 2
    let hourLength = globeR * 0.55
    let hourHand = NSBezierPath()
    hourHand.move(to: center)
    hourHand.line(to: NSPoint(
        x: center.x + cos(hourAngle) * hourLength,
        y: center.y + sin(hourAngle) * hourLength
    ))
    hourHand.lineCapStyle = .round
    drawNeonGlow(ctx: ctx, path: hourHand, color: .white, glowRadius: glowSize, coreWidth: s * 0.02)

    // Minute hand (~12 o'clock)
    let minuteAngle = CGFloat.pi / 2
    let minuteLength = globeR * 0.78
    let minuteHand = NSBezierPath()
    minuteHand.move(to: center)
    minuteHand.line(to: NSPoint(
        x: center.x + cos(minuteAngle) * minuteLength,
        y: center.y + sin(minuteAngle) * minuteLength
    ))
    minuteHand.lineCapStyle = .round
    drawNeonGlow(ctx: ctx, path: minuteHand, color: .white, glowRadius: glowSize * 0.8, coreWidth: s * 0.014)

    // Center dot — neon glow
    let dotR = s * 0.018
    let dotPath = NSBezierPath(ovalIn: NSRect(
        x: center.x - dotR, y: center.y - dotR,
        width: dotR * 2, height: dotR * 2
    ))
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: glowSize, color: neonCyan.cgColor)
    NSColor.white.setFill()
    dotPath.fill()
    ctx.restoreGState()
    NSColor.white.setFill()
    dotPath.fill()

    image.unlockFocus()
    return image
}

// Create output directory
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

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
