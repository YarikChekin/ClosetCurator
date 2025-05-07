import Foundation
import Vision
import CoreML
import UIKit
import SwiftUI

@MainActor
final class ClothingDetectionService: ObservableObject {
    @Published private(set) var isProcessing = false
    @Published private(set) var error: Error?
    
    private var classificationRequest: VNCoreMLRequest?
    
    init() {
        DebugLogger.info("ClothingDetectionService initializing")
        setupVision()
    }
    
    private func setupVision() {
        do {
            // Using our placeholder ML model
            let config = MLModelConfiguration()
            DebugLogger.info("Setting up Vision with ML model configuration")
            let model = try VNCoreMLModel(for: YourClothingClassifier(configuration: config).model)
            
            classificationRequest = VNCoreMLRequest(model: model) { [weak self] request, error in
                if let error = error {
                    DebugLogger.error("Vision request error: \(error.localizedDescription)")
                    self?.error = error
                    return
                }
                
                self?.processClassifications(for: request)
            }
            
            classificationRequest?.imageCropAndScaleOption = .centerCrop
            DebugLogger.info("Vision setup completed successfully")
        } catch {
            DebugLogger.error("Failed to set up Vision: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func detectClothing(in image: UIImage) async throws -> ClothingItem? {
        DebugLogger.info("Starting clothing detection")
        isProcessing = true
        defer { isProcessing = false }
        
        guard let cgImage = image.cgImage else {
            DebugLogger.error("Failed to get CGImage from UIImage")
            throw ClothingDetectionError.invalidImage
        }
        
        DebugLogger.info("Image dimensions: \(cgImage.width)x\(cgImage.height)")
        
        // In a real app, we would use Vision to process the image
        // For now, we'll simulate the process using our placeholder model
        
        // Option 1: Use direct prediction from our placeholder model
        let classifier = try YourClothingClassifier()
        DebugLogger.info("Using classifier to predict image content")
        let prediction = try classifier.prediction(input: cgImage)
        
        DebugLogger.info("Prediction result: \(prediction.classLabel) with confidence \(prediction.probability)")
        
        // Create a clothing item from the simulated prediction
        let item = try await createClothingItem(
            from: prediction.classLabel,
            confidence: prediction.probability,
            image: image
        )
        
        DebugLogger.info("Created ClothingItem: \(item.name) with category \(item.category)")
        return item
    }
    
    private func processClassifications(for request: VNRequest) {
        // Handle classification results
        guard let results = request.results as? [VNClassificationObservation] else {
            DebugLogger.error("No valid classification results")
            return
        }
        
        // Process the results as needed
        DebugLogger.info("Classification results:")
        for classification in results {
            DebugLogger.info("  - \(classification.identifier): \(classification.confidence)")
        }
    }
    
    private func createClothingItem(from label: String, confidence: Double, image: UIImage) async throws -> ClothingItem {
        // Extract category from the classification
        let category = try determineCategory(from: label)
        DebugLogger.info("Determined category: \(category) from label: \(label)")
        
        // Save the image to get a URL
        let imageURL = try await saveImage(image)
        DebugLogger.info("Saved image to: \(imageURL)")
        
        // Create and return the clothing item
        return ClothingItem(
            name: label,
            category: category,
            color: "Unknown", // TODO: Implement color detection
            imageURL: imageURL,
            mlConfidence: confidence
        )
    }
    
    private func determineCategory(from identifier: String) throws -> ClothingCategory {
        // Map the classification to a clothing category
        DebugLogger.info("Determining category for: \(identifier)")
        let result: ClothingCategory
        
        switch identifier.lowercased() {
        case let str where str.contains("shirt") || str.contains("top"):
            result = .tops
        case let str where str.contains("pants") || str.contains("jeans"):
            result = .bottoms
        case let str where str.contains("dress"):
            result = .dresses
        case let str where str.contains("jacket") || str.contains("coat"):
            result = .outerwear
        case let str where str.contains("shoe") || str.contains("boot"):
            result = .shoes
        default:
            result = .accessories
        }
        
        DebugLogger.info("Category determined: \(result)")
        return result
    }
    
    private func saveImage(_ image: UIImage) async throws -> URL {
        // Get the documents directory URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        DebugLogger.info("Documents directory: \(documentsDirectory)")
        
        // Create a unique filename with the current date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "clothing_\(dateString).jpg"
        
        // Create the file URL
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        DebugLogger.info("Saving image to: \(fileURL)")
        
        // Convert the image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            DebugLogger.error("Failed to convert image to JPEG data")
            throw ClothingDetectionError.invalidImage
        }
        
        DebugLogger.info("Image size: \(imageData.count) bytes")
        
        do {
            // Write the data to the file URL
            try imageData.write(to: fileURL)
            DebugLogger.info("Image saved successfully")
            return fileURL
        } catch {
            DebugLogger.error("Failed to save image: \(error.localizedDescription)")
            throw error
        }
    }
}

enum ClothingDetectionError: Error, Equatable {
    case invalidImage
    case noResults
    case notImplemented
} 