import AppKit
import Foundation

let assetRoot = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let blue = NSColor(calibratedRed: 0.07, green: 0.38, blue: 0.87, alpha: 1)
let background = NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.985, alpha: 1)

func render(size: Int, symbol: CGFloat, file: URL) throws {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB,
                                      bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Cannot draw icon") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    background.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    let left = (CGFloat(size) - symbol) / 2
    let bottom = left
    func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: left + x * symbol / 32, y: bottom + y * symbol / 32)
    }
    blue.setStroke()
    let rays = NSBezierPath()
    rays.lineWidth = symbol * 0.9 / 32
    rays.lineCapStyle = .round
    for (a, b) in [((3.0, 10.0), (29.0, 22.0)),
                   ((3.0, 22.0), (29.0, 10.0)),
                   ((3.0, 16.0), (29.0, 16.0))] {
        rays.move(to: point(a.0, a.1))
        rays.line(to: point(b.0, b.1))
    }
    rays.stroke()
    let lens = NSBezierPath(ovalIn: NSRect(x: left + 12 * symbol / 32,
                                          y: bottom + 3 * symbol / 32,
                                          width: 8 * symbol / 32,
                                          height: 26 * symbol / 32))
    lens.lineWidth = symbol * 1.05 / 32
    lens.stroke()
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode icon") }
    try data.write(to: file)
}

try render(size: 1024, symbol: 690, file: assetRoot.appendingPathComponent("AppIcon.appiconset/AppIcon-512@2x.png"))
for name in ["splash-2732x2732.png", "splash-2732x2732-1.png", "splash-2732x2732-2.png"] {
    try render(size: 2732, symbol: 510, file: assetRoot.appendingPathComponent("Splash.imageset/\(name)"))
}
