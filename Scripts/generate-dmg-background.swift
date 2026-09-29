#!/usr/bin/env swift

// Generates the DMG window background, matching the app icon's neon palette.
// Layout constants must agree with Resources/dmg-settings.py.

import AppKit
import Foundation

let width: CGFloat = 640
let height: CGFloat = 400
let iconY: CGFloat = 190  // icon centre, measured from the top like Finder
let appX: CGFloat = 160
let applicationsX: CGFloat = 480
let labelY: CGFloat = 265  // Finder draws labels black on image backgrounds, so they sit on plates

let neonCyan = NSColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 1.0)
let neonMagenta = NSColor(red: 0.95, green: 0.15, blue: 0.60, alpha: 1.0)
let neonPurple = NSColor(red: 0.60, green: 0.20, blue: 0.95, alpha: 1.0)

// Drawing uses a bottom-left origin; Finder positions are top-left.
func flip(_ y: CGFloat) -> CGFloat { height - y }

func glowStroke(_ ctx: CGContext, _ path: NSBezierPath, _ color: NSColor, width: CGFloat, blur: CGFloat) {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: blur, color: color.cgColor)
    color.withAlphaComponent(0.5).setStroke()
    path.lineWidth = width * 2
    path.stroke()
    ctx.restoreGState()
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func drawText(_ ctx: CGContext, _ text: String, font: NSFont, color: NSColor, kern: CGFloat, centreY: CGFloat, glow: NSColor?) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .kern: kern]
    let str = NSAttributedString(string: text, attributes: attrs)
    let size = str.size()
    let origin = NSPoint(x: (width - size.width + kern) / 2, y: flip(centreY) - size.height / 2)
    ctx.saveGState()
    if let glow { ctx.setShadow(offset: .zero, blur: 14, color: glow.cgColor) }
    str.draw(at: origin)
    ctx.restoreGState()
}

func render(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // Void
    NSGradient(colorsAndLocations:
        (NSColor(red: 0.07, green: 0.03, blue: 0.16, alpha: 1), 0.0),
        (NSColor(red: 0.04, green: 0.02, blue: 0.10, alpha: 1), 0.55),
        (NSColor(red: 0.02, green: 0.01, blue: 0.05, alpha: 1), 1.0)
    )!.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    // Stars, deterministic so regenerating yields the same image
    var seed: UInt64 = 0x2077
    func rand() -> CGFloat {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
    }
    for _ in 0..<90 {
        let x = rand() * width, y = rand() * 290, r = 0.3 + rand() * 0.9
        NSColor.white.withAlphaComponent(0.1 + rand() * 0.35).setFill()
        NSBezierPath(ovalIn: NSRect(x: x - r, y: flip(y) - r, width: r * 2, height: r * 2)).fill()
    }

    // Perspective grid floor
    let horizon: CGFloat = 318
    let vanishing = NSPoint(x: width / 2, y: flip(horizon - 60))
    ctx.saveGState()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: flip(horizon))).addClip()
    NSGradient(colorsAndLocations:
        (neonPurple.withAlphaComponent(0.18), 0.0),
        (neonPurple.withAlphaComponent(0.0), 1.0)
    )!.draw(in: NSRect(x: 0, y: 0, width: width, height: flip(horizon)), angle: 90)
    for i in -14...14 {
        let line = NSBezierPath()
        line.move(to: vanishing)
        line.line(to: NSPoint(x: width / 2 + CGFloat(i) * 70, y: -10))
        neonMagenta.withAlphaComponent(0.28).setStroke()
        line.lineWidth = 1
        line.stroke()
    }
    for i in 0..<9 {
        let t = pow(CGFloat(i) / 8, 1.8)
        let y = flip(horizon) * (1 - t)
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 0, y: y))
        line.line(to: NSPoint(x: width, y: y))
        neonMagenta.withAlphaComponent(0.12 + 0.3 * (1 - t)).setStroke()
        line.lineWidth = 1
        line.stroke()
    }
    // Fade the grid into the horizon
    NSGradient(colorsAndLocations:
        (NSColor(red: 0.03, green: 0.01, blue: 0.08, alpha: 0.0), 0.0),
        (NSColor(red: 0.03, green: 0.01, blue: 0.08, alpha: 0.85), 1.0)
    )!.draw(in: NSRect(x: 0, y: flip(horizon) - 40, width: width, height: 40), angle: 90)
    ctx.restoreGState()

    NSGradient(colors: [neonMagenta.withAlphaComponent(0), neonMagenta, neonCyan, neonCyan.withAlphaComponent(0)])!
        .draw(in: NSRect(x: 0, y: flip(horizon) - 1, width: width, height: 2), angle: 0)

    // Halos behind the two icon slots
    for x in [appX, applicationsX] {
        let c = NSPoint(x: x, y: flip(iconY))
        NSGradient(colorsAndLocations:
            (neonPurple.withAlphaComponent(0.30), 0.0),
            (neonPurple.withAlphaComponent(0.0), 1.0)
        )!.draw(fromCenter: c, radius: 0, toCenter: c, radius: 110, options: [])
    }

    for (x, glow) in [(appX, neonMagenta), (applicationsX, neonCyan)] {
        let plate = NSBezierPath(
            roundedRect: NSRect(x: x - 78, y: flip(labelY) - 11, width: 156, height: 22),
            xRadius: 11, yRadius: 11)
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 14, color: glow.cgColor)
        NSColor(red: 0.93, green: 0.91, blue: 1.0, alpha: 0.92).setFill()
        plate.fill()
        ctx.restoreGState()
        glow.withAlphaComponent(0.9).setStroke()
        plate.lineWidth = 1
        plate.stroke()
    }

    // Chevrons from app to Applications, magenta through to cyan
    for i in 0..<3 {
        let t = CGFloat(i) / 2
        let x = 290 + CGFloat(i) * 30
        let chevron = NSBezierPath()
        chevron.move(to: NSPoint(x: x, y: flip(iconY - 16)))
        chevron.line(to: NSPoint(x: x + 14, y: flip(iconY)))
        chevron.line(to: NSPoint(x: x, y: flip(iconY + 16)))
        chevron.lineCapStyle = .round
        chevron.lineJoinStyle = .round
        let colour = neonMagenta.blended(withFraction: t, of: neonCyan)!
        glowStroke(ctx, chevron, colour, width: 3.5, blur: 10)
    }

    drawText(ctx, "BrowserSchedule",
             font: .systemFont(ofSize: 30, weight: .heavy), color: .white, kern: 0.5,
             centreY: 50, glow: neonCyan)
    drawText(ctx, "THE RIGHT BROWSER AT THE RIGHT TIME",
             font: .monospacedSystemFont(ofSize: 10, weight: .semibold),
             color: neonCyan.withAlphaComponent(0.8), kern: 3, centreY: 82, glow: nil)
    drawText(ctx, "DRAG TO APPLICATIONS TO INSTALL",
             font: .monospacedSystemFont(ofSize: 10, weight: .semibold),
             color: NSColor.white.withAlphaComponent(0.9), kern: 3, centreY: 362, glow: neonMagenta)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
for (scale, name) in [(1.0, "dmg-background.png"), (2.0, "dmg-background@2x.png")] {
    let png = render(scale: scale).representation(using: .png, properties: [:])!
    try png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("Generated \(name)")
}
