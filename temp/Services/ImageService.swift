import Foundation
import UIKit
import Vision

actor ImageService {
    static let shared = ImageService()
    
    private let fileManager = FileManager.default
    private let imagesDirectory: URL
    
    private init() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imagesDirectory = documentsDirectory.appendingPathComponent("Images", isDirectory: true)
        
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }
    
    func saveImage(_ imageData: Data, for item: ClothingItem) async throws -> URL {
        let fileName = "\(item.id.uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        try imageData.write(to: fileURL)
        return fileURL
    }
    
    func removeImage(for item: ClothingItem) async throws {
        guard let imageURL = item.imageURL else { return }
        try fileManager.removeItem(at: imageURL)
    }
    
    func processImage(_ imageData: Data) async throws -> Data {
        guard let uiImage = UIImage(data: imageData) else {
            throw ImageError.invalidImageData
        }
        
        // Create a request to segment the person from the background
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        // Create a handler to process the request
        let handler = VNImageRequestHandler(cgImage: uiImage.cgImage!, options: [:])
        try handler.perform([request])
        
        guard let mask = request.results?.first else {
            throw ImageError.processingFailed
        }
        
        // Create a new image with transparent background
        let maskImage = mask.pixelBuffer
        let processedImage = try await removeBackground(from: uiImage, using: maskImage)
        
        // Convert the processed image to JPEG data
        guard let processedData = processedImage.jpegData(compressionQuality: 0.8) else {
            throw ImageError.processingFailed
        }
        
        return processedData
    }
    
    private func removeBackground(from image: UIImage, using mask: CVPixelBuffer) async throws -> UIImage {
        let ciImage = CIImage(cgImage: image.cgImage!)
        let maskImage = CIImage(cvPixelBuffer: mask)
        
        // Scale the mask to match the image size
        let scaleX = ciImage.extent.width / maskImage.extent.width
        let scaleY = ciImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Create a filter to apply the mask
        guard let filter = CIFilter(name: "CIBlendWithMask") else {
            throw ImageError.processingFailed
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = filter.outputImage else {
            throw ImageError.processingFailed
        }
        
        // Create a context to render the final image
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw ImageError.processingFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
}

enum ImageError: Error {
    case invalidImageData
    case processingFailed
    case saveFailed
    case removeFailed
} 