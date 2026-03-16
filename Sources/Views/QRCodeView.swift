import SwiftUI
import CoreImage.CIFilterBuiltins

/// Renders a string as a QR code using CoreImage.
struct QRCodeView: View {
    let content: String

    var body: some View {
        if let image = makeQRCode(from: content) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Text("QR unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                )
        }
    }

    private func makeQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter  = CIFilter.qrCodeGenerator()
        filter.message         = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let raw = filter.outputImage else { return nil }
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
