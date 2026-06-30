import UIKit
import CoreImage
import Metal

@MainActor
final class RegionCapture {
    /// A long-lived context. Metal-backed when a device is available, else default.
    nonisolated static let sharedContext: CIContext = {
        if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device, options: [.workingColorSpace: NSNull()])
        }
        return CIContext(options: [.workingColorSpace: NSNull()])
    }()

    /// Average color of `image` reduced to one pixel via CIAreaAverage, returned as
    /// linearized Rec.709 relative luminance. `nonisolated` so it can run off-main.
    nonisolated static func averageLuminance(of image: CIImage, context: CIContext) -> CGFloat? {
        let extent = image.extent
        guard extent.width > 0, extent.height > 0, extent.isInfinite == false else { return nil }
        let extentVector = CIVector(x: extent.origin.x, y: extent.origin.y,
                                    z: extent.size.width, w: extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: image,
                                                 kCIInputExtentKey: extentVector]),
              let output = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &bitmap, rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
        let r = CGFloat(bitmap[0]) / 255, g = CGFloat(bitmap[1]) / 255, b = CGFloat(bitmap[2]) / 255
        return LuminanceMath.relativeLuminance(r: r, g: g, b: b)
    }
}
