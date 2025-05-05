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
        
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
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
    
    func processImage(_ image: UIImage) async throws -> URL {
        // This would normally perform image processing like background removal,
        // color correction, etc. For now, we'll just return a compressed jpeg
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.processingFailed
        }
        
        // Save to a temporary file
        let tempID = UUID()
        let tempURL = imagesDirectory.appendingPathComponent("\(tempID.uuidString)_temp.jpg")
        try imageData.write(to: tempURL)
        
        return tempURL
    }
    
    enum ImageError: Error {
        case processingFailed
        case saveFailed
        case loadFailed
    }
} 