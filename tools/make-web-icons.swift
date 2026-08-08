// Compõe os ícones do web app a partir da mesma arte do Icon Composer do app iOS,
// para que o ícone na tela de início seja o mesmo nos dois.
//
// Gradiente e camada vêm de Artikel/Logo.icon/icon.json.

import AppKit
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("uso: MakeIcons <logo.png> <pasta-saida>\n".data(using: .utf8)!)
    exit(1)
}
let logoPath = args[1]
let outDir = URL(fileURLWithPath: args[2])

guard let logoImage = NSImage(contentsOfFile: logoPath),
      let logoCG = logoImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("não consegui ler \(logoPath)\n".data(using: .utf8)!)
    exit(1)
}

// Display P3, exatamente como no icon.json.
let p3 = CGColorSpace(name: CGColorSpace.displayP3)!
let topColor = CGColor(colorSpace: p3, components: [0.87262, 1.00000, 0.98581, 1.0])!
let bottomColor = CGColor(colorSpace: p3, components: [0.84010, 0.79345, 0.96783, 1.0])!

/// `inset` = fração de margem em cada lado (para a variante maskable do Android).
func renderIcon(size: Int, inset: CGFloat = 0) -> CGImage? {
    let s = CGFloat(size)
    guard let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    ctx.interpolationQuality = .high

    // fundo: gradiente diagonal, do canto superior esquerdo ao inferior direito
    if let gradient = CGGradient(colorsSpace: p3, colors: [topColor, bottomColor] as CFArray,
                                 locations: [0, 1]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: s, y: 0),
                               options: [])
    }

    // logo centrado, ocupando ~86% do lado (menos, quando há inset da safe zone)
    let usable = s * (1 - 2 * inset)
    let target = usable * 0.86
    let aspect = CGFloat(logoCG.width) / CGFloat(logoCG.height)
    let w = aspect >= 1 ? target : target * aspect
    let h = aspect >= 1 ? target / aspect : target
    let rect = CGRect(x: (s - w) / 2, y: (s - h) / 2, width: w, height: h)

    ctx.draw(logoCG, in: rect)
    return ctx.makeImage()
}

func write(_ image: CGImage, to name: String) {
    let url = outDir.appendingPathComponent(name)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { return }
    CGImageDestinationAddImage(dest, image, nil)
    if CGImageDestinationFinalize(dest) {
        print("  \(name)  \(image.width)x\(image.height)")
    }
}

import ImageIO

for size in [180, 192, 512] {
    if let img = renderIcon(size: size) { write(img, to: "icon-\(size).png") }
}
// maskable: conteúdo dentro da safe zone circular do Android (margem de 10%)
if let img = renderIcon(size: 512, inset: 0.10) { write(img, to: "icon-maskable-512.png") }
