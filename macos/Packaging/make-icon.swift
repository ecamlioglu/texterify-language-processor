import AppKit
import Foundation

let directory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: pixels, height: pixels)
        NSColor(calibratedRed: 0.34, green: 0.31, blue: 0.72, alpha: 1).setFill()
        NSBezierPath(roundedRect: rect.insetBy(dx: Double(pixels) * 0.08, dy: Double(pixels) * 0.08), xRadius: Double(pixels) * 0.2, yRadius: Double(pixels) * 0.2).fill()
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: Double(pixels) * 0.5, weight: .medium), .foregroundColor: NSColor.white]
        let label = NSAttributedString(string: "Tr", attributes: attributes)
        let bounds = label.size()
        label.draw(at: NSPoint(x: (Double(pixels) - bounds.width) / 2, y: (Double(pixels) - bounds.height) / 2))
        image.unlockFocus()
        let representation = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let suffix = scale == 2 ? "@2x" : ""
        try representation.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
