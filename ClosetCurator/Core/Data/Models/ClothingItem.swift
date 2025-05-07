import Foundation
import SwiftData
import CoreML
import Vision

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    var category: ClothingCategory
    var subcategory: String?
    var color: String
    var brand: String?
    var size: String?
    var notes: String?
    var dateAdded: Date
    var imageURL: URL?
    @Relationship(deleteRule: .cascade) var outfits: [Outfit]?
    var wearCount: Int
    var lastWorn: Date?
    var favorite: Bool
    var mlConfidence: Double?
    
    // Style-related properties
    var styleTags: [StyleTag]
    
    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        subcategory: String? = nil,
        color: String,
        brand: String? = nil,
        size: String? = nil,
        notes: String? = nil,
        dateAdded: Date = Date(),
        imageURL: URL? = nil,
        outfits: [Outfit]? = nil,
        wearCount: Int = 0,
        lastWorn: Date? = nil,
        favorite: Bool = false,
        mlConfidence: Double? = nil,
        styleTags: [StyleTag] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.color = color
        self.brand = brand
        self.size = size
        self.notes = notes
        self.dateAdded = dateAdded
        self.imageURL = imageURL
        self.outfits = outfits
        self.wearCount = wearCount
        self.lastWorn = lastWorn
        self.favorite = favorite
        self.mlConfidence = mlConfidence
        self.styleTags = styleTags
        
        DebugLogger.info("ClothingItem initialized: \(name) (ID: \(id))")
        if let url = imageURL {
            DebugLogger.info("  - Image URL: \(url)")
            // Check if the image file exists
            if FileManager.default.fileExists(atPath: url.path) {
                DebugLogger.info("  - Image file exists")
            } else {
                DebugLogger.error("  - Image file does not exist at path: \(url.path)")
            }
        }
    }
    
    // MARK: - Usage Tracking
    
    func markAsWorn() {
        wearCount += 1
        lastWorn = Date()
        DebugLogger.info("Item marked as worn: \(name), count: \(wearCount)")
    }
}

enum ClothingCategory: String, Codable, CaseIterable {
    case tops
    case bottoms
    case dresses
    case outerwear
    case shoes
    case accessories
}

enum StyleTag: String, Codable, CaseIterable {
    case casual
    case formal
    case business
    case sporty
    case elegant
    case vintage
    case modern
} 