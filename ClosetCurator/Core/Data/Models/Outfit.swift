import Foundation
import SwiftData

@Model
final class Outfit {
    var id: UUID
    var name: String
    @Relationship(inverse: \ClothingItem.outfits) var items: [ClothingItem]
    var dateCreated: Date
    var lastWorn: Date?
    var wearCount: Int
    var favorite: Bool
    var notes: String?
    var styleTags: [StyleTag]
    var rating: Int?
    
    init(
        id: UUID = UUID(),
        name: String,
        items: [ClothingItem],
        dateCreated: Date = Date(),
        lastWorn: Date? = nil,
        wearCount: Int = 0,
        favorite: Bool = false,
        notes: String? = nil,
        styleTags: [StyleTag] = [],
        rating: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.dateCreated = dateCreated
        self.lastWorn = lastWorn
        self.wearCount = wearCount
        self.favorite = favorite
        self.notes = notes
        self.styleTags = styleTags
        self.rating = rating
    }
    
    // MARK: - Usage Tracking
    
    func markAsWorn() {
        wearCount += 1
        lastWorn = Date()
        items.forEach { $0.markAsWorn() }
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        // Ensure the outfit has at least one item
        guard !items.isEmpty else { return false }
        
        // Check for required categories
        let categories = Set(items.map { $0.category })
        let hasTop = categories.contains(.tops) || categories.contains(.dresses)
        let hasBottom = categories.contains(.bottoms) || categories.contains(.dresses)
        
        return hasTop && hasBottom
    }
} 