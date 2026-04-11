#!/usr/bin/env swift

import AppKit
import CoreGraphics
import CoreText

let width = 1200
let height = 800
let scale: CGFloat = 2.0

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Failed to create graphics context")
}

// Background gradient: subtle warm gray to white
let gradientColors = [
    CGColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1.0),
    CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: Double(height)),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// Arrow: curved arc from app icon area (left) to Applications area (right)
// At @2x: app icon center ~x=280, Applications center ~x=800
// Arrow spans the gap between them, at icon vertical center
let arrowY = Double(height) * 0.55
let arrowStartX = 350.0
let arrowEndX = 730.0
let arrowMidX = (arrowStartX + arrowEndX) / 2.0

ctx.setStrokeColor(CGColor(red: 0.50, green: 0.50, blue: 0.55, alpha: 0.45))
ctx.setLineWidth(2.5)
ctx.setLineCap(.round)

// Curved arrow body — arc upward
ctx.move(to: CGPoint(x: arrowStartX, y: arrowY))
ctx.addQuadCurve(
    to: CGPoint(x: arrowEndX - 20, y: arrowY),
    control: CGPoint(x: arrowMidX, y: arrowY + 60)
)
ctx.strokePath()

// Arrowhead
let headSize = 12.0
ctx.move(to: CGPoint(x: arrowEndX - 20, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowEndX - 20 - headSize, y: arrowY - headSize))
ctx.move(to: CGPoint(x: arrowEndX - 20, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowEndX - 20 - headSize, y: arrowY + headSize))
ctx.strokePath()

// "Drag to install" text — below the icons
let textY = Double(height) * 0.22
let text = "Drag to Applications to install" as CFString
let font = CTFontCreateWithName("Helvetica Neue" as CFString, 22.0, nil)
let attributes: [CFString: Any] = [
    kCTFontAttributeName: font,
    kCTForegroundColorAttributeName: CGColor(red: 0.45, green: 0.45, blue: 0.50, alpha: 0.7)
]
let attrString = CFAttributedStringCreate(nil, text, attributes as CFDictionary)!
let line = CTLineCreateWithAttributedString(attrString)
let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
let textX = (Double(width) - textBounds.width) / 2.0

ctx.textPosition = CGPoint(x: textX, y: textY)
CTLineDraw(line, ctx)

// Save
guard let image = ctx.makeImage() else {
    fatalError("Failed to create image")
}

let url = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-background.png")
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Failed to create image destination")
}

// Set DPI to 144 (Retina @2x)
let properties: [CFString: Any] = [
    kCGImagePropertyDPIWidth: 144.0,
    kCGImagePropertyDPIHeight: 144.0
]
CGImageDestinationAddImage(dest, image, properties as CFDictionary)
CGImageDestinationFinalize(dest)

print("Generated DMG background: \(url.path)")
