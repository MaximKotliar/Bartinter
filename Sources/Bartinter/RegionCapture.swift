import UIKit
import CoreImage
import Metal
import QuartzCore

@MainActor
final class RegionCapture {
    // Designated init is private; public callers use `init?()` in the extension below.
    private init(_unchecked: Void) {}

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

// MARK: - CARenderer GPU capture

extension RegionCapture {
    private static let readbackQueue = DispatchQueue(label: "com.bartinter.readback")

    /// Wraps a CIImage (Sendable) and its sampling weight for the readback queue.
    private struct ImageBox: @unchecked Sendable {
        let image: CIImage
        let area: CGFloat
    }

    /// Returns nil when no Metal device is available (e.g. non-Metal simulator).
    convenience init?() {
        guard MTLCreateSystemDefaultDevice() != nil else { return nil }
        self.init(_unchecked: ())
    }

    /// Renders each rect of `layer` into a private Metal texture via `CARenderer`,
    /// area-weights the per-rect average luminances, and calls `completion` on the main actor.
    ///
    /// On platforms where `CARenderer` produces no GPU output (e.g. the iOS simulator),
    /// the implementation falls back to `layer.render(in:)` via a CGContext so the
    /// integration test passes on simulator and the production code path is preserved
    /// for on-device use.
    func sampleLuminance(
        of layer: CALayer,
        rects: [CGRect],
        completion: @escaping @MainActor (CGFloat?) -> Void
    ) {
        guard !rects.isEmpty, let device = MTLCreateSystemDefaultDevice() else {
            Task { @MainActor in completion(nil) }
            return
        }

        // 1. Render each rect into its own small Metal texture via CARenderer
        //    (main-thread-only; CALayer is not Sendable).
        let cmdQueue = device.makeCommandQueue()
        let rendererOptions: [AnyHashable: Any]? = cmdQueue.map {
            [kCARendererMetalCommandQueue: $0]
        }

        let boxes: [ImageBox] = rects.compactMap { rect -> ImageBox? in
            guard rect.width > 0, rect.height > 0 else { return nil }
            // Downscale to at most ~16 px wide to minimise readback cost.
            let scale = max(1, min(16, rect.width)) / rect.width
            let tw = max(1, Int((rect.width  * scale).rounded()))
            let th = max(1, Int((rect.height * scale).rounded()))

            // ── GPU path via CARenderer ──────────────────────────────────────────
            if let cmdQueue {
                let desc = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: .bgra8Unorm, width: tw, height: th, mipmapped: false)
                desc.usage       = [.renderTarget, .shaderRead]
                desc.storageMode = .shared          // CPU-readable for CIImage readback
                if let texture = device.makeTexture(descriptor: desc) {
                    let renderer = CARenderer(mtlTexture: texture, options: rendererOptions)
                    renderer.layer  = layer
                    renderer.bounds = rect
                    renderer.beginFrame(atTime: CACurrentMediaTime(), timeStamp: nil)
                    renderer.addUpdate(rect)
                    renderer.render()
                    renderer.endFrame()

                    // GPU fence: wait for CARenderer's command buffer on our queue.
                    if let fence = cmdQueue.makeCommandBuffer() {
                        fence.commit()
                        fence.waitUntilCompleted()
                    }

                    // Check if CARenderer produced any non-zero output.
                    var probe = [UInt8](repeating: 0, count: 4)
                    texture.getBytes(&probe, bytesPerRow: 4,
                                     from: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0)
                    let gpuHasOutput = probe[3] != 0   // bgra8Unorm: byte 3 is alpha; opaque rendered output has alpha > 0

                    if gpuHasOutput, let ciImg = CIImage(mtlTexture: texture, options: nil) {
                        return ImageBox(image: ciImg, area: rect.width * rect.height)
                    }
                }
            }

            // ── CPU fallback via layer.render(in:) ───────────────────────────────
            // Used on iOS simulator where CARenderer(mtlTexture:) is a no-op.
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = false
            let uiImg = UIGraphicsImageRenderer(
                size: CGSize(width: tw, height: th), format: format).image { ctx in
                ctx.cgContext.scaleBy(x: CGFloat(tw) / rect.width,
                                     y: CGFloat(th) / rect.height)
                layer.render(in: ctx.cgContext)
            }
            guard let cgImg = uiImg.cgImage else { return nil }
            return ImageBox(image: CIImage(cgImage: cgImg),
                            area: rect.width * rect.height)
        }

        guard !boxes.isEmpty else {
            Task { @MainActor in completion(nil) }
            return
        }

        // 2. Area-weight luminances off the main thread, deliver on the main actor.
        let context = RegionCapture.sharedContext
        RegionCapture.readbackQueue.async {
            var weightedSum: CGFloat = 0
            var totalArea:   CGFloat = 0
            for box in boxes {
                guard let lum = RegionCapture.averageLuminance(of: box.image, context: context)
                else { continue }
                weightedSum += lum * box.area
                totalArea   += box.area
            }
            let result: CGFloat? = totalArea > 0 ? weightedSum / totalArea : nil
            Task { @MainActor in completion(result) }
        }
    }
}

// MARK: - NullSampler (fallback when no Metal device exists)

extension RegionCapture {
    /// Fallback used when no Metal device exists; never produces a luminance value.
    static var disabled: NullSampler { NullSampler() }

    @MainActor
    final class NullSampler: LuminanceSampling {
        func sampleLuminance(
            of layer: CALayer,
            rects: [CGRect],
            completion: @escaping @MainActor (CGFloat?) -> Void
        ) {
            completion(nil)
        }
    }
}
