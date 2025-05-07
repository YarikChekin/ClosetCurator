import UIKit
import Vision

class ImageService {
    enum ImageError: Error {
        case invalidImageData
        case processingFailed
    }
    
    func processImage(_ imageData: Data) async throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw ImageError.invalidImageData
        }
        
        // Resize the image if it's too large
        let maxDimension: CGFloat = 1024
        let resizedImage = await resizeImageIfNeeded(image, maxDimension: maxDimension)
        
        // Remove background
        let processedImage = try await removeBackground(from: resizedImage)
        
        // Convert back to data
        guard let processedData = processedImage.pngData() else {
            throw ImageError.processingFailed
        }
        
        return processedData
    }
    
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) async -> UIImage {
        let size = image.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let ratio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        return await withCheckedContinuation { continuation in
            UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            continuation.resume(returning: resizedImage)
        }
    }
    
    private func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageError.processingFailed
        }
        
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let mask = request.results?.first?.pixelBuffer else {
            throw ImageError.processingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let maskImage = try self.createMaskImage(from: mask, originalImage: image)
                    let maskedImage = try self.blend(image: image, with: maskImage)
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createMaskImage(from pixelBuffer: CVPixelBuffer, originalImage: UIImage) throws -> CGImage {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ImageError.processingFailed
        }
        
        let context = CGContext(data: baseAddress,
                              width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bytesPerRow: bytesPerRow,
                              space: CGColorSpaceCreateDeviceGray(),
                              bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        guard let mask = context?.makeImage() else {
            throw ImageError.processingFailed
        }
        
        return mask
    }
    
    private func blend(image: UIImage, with mask: CGImage) throws -> UIImage {
        let scale = image.scale
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            throw ImageError.processingFailed
        }
        
        let rect = CGRect(origin: .zero, size: size)
        
        context.saveGState()
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: rect)
        }
        
        context.clip(to: rect, mask: mask)
        context.clear(rect)
        
        context.restoreGState()
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: rect)
        }
        
        guard let processedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            throw ImageError.processingFailed
        }
        
        return processedImage
    }
} 