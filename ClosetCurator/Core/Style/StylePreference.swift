import Foundation
import SwiftData

/// StylePreference represents a user's style preferences learned from their inputs and vision boards
@Model
final class StylePreference {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // Core style attributes
    var favoriteColors: [String]
    var favoriteStyles: [StyleTag]
    var favoredBrands: [String]
    var favoredFits: [FitPreference]
    
    // Style exploration parameters
    var adventureLevel: Double // 0.0 (conservative) to 1.0 (adventurous)
    var seasonalPreference: [Season: Double] // Preference strength for each season
    
    // Relationship to vision boards
    @Relationship(deleteRule: .cascade, inverse: \StyleBoard.preference)
    var styleBoards: [StyleBoard]?
    
    // Relationship to user feedback on recommendations
    @Relationship(deleteRule: .cascade)
    var styleFeedback: [StyleFeedback]?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        favoriteColors: [String] = [],
        favoriteStyles: [StyleTag] = [],
        favoredBrands: [String] = [],
        favoredFits: [FitPreference] = [],
        adventureLevel: Double = 0.5,
        seasonalPreference: [Season: Double] = [:],
        styleBoards: [StyleBoard]? = nil,
        styleFeedback: [StyleFeedback]? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.favoriteColors = favoriteColors
        self.favoriteStyles = favoriteStyles
        self.favoredBrands = favoredBrands
        self.favoredFits = favoredFits
        self.adventureLevel = adventureLevel
        self.seasonalPreference = seasonalPreference
        self.styleBoards = styleBoards
        self.styleFeedback = styleFeedback
    }
    
    // MARK: - Helper Methods
    
    /// Updates the style preference based on new user input
    func updatePreferences(newColors: [String]? = nil, newStyles: [StyleTag]? = nil, 
                          newBrands: [String]? = nil, newFits: [FitPreference]? = nil) {
        if let newColors = newColors {
            favoriteColors = mergeSortedByFrequency(existing: favoriteColors, new: newColors)
        }
        
        if let newStyles = newStyles {
            favoriteStyles = mergeSortedByFrequency(existing: favoriteStyles, new: newStyles)
        }
        
        if let newBrands = newBrands {
            favoredBrands = mergeSortedByFrequency(existing: favoredBrands, new: newBrands)
        }
        
        if let newFits = newFits {
            favoredFits = mergeSortedByFrequency(existing: favoredFits, new: newFits)
        }
        
        updatedAt = Date()
    }
    
    /// Updates the adventure level based on user feedback
    func updateAdventureLevel(newLevel: Double) {
        // Gradually adjust adventure level to avoid drastic changes
        adventureLevel = (adventureLevel * 0.7) + (newLevel * 0.3)
        updatedAt = Date()
    }
    
    /// Helper to merge and sort arrays by frequency
    private func mergeSortedByFrequency<T: Hashable>(existing: [T], new: [T]) -> [T] {
        var frequencyDict: [T: Int] = [:]
        
        // Count existing items with higher weight
        for item in existing {
            frequencyDict[item, default: 0] += 2
        }
        
        // Add new items
        for item in new {
            frequencyDict[item, default: 0] += 1
        }
        
        // Sort by frequency and return
        return frequencyDict.sorted { $0.value > $1.value }.map { $0.key }
    }
}

/// Represents user's fit preferences for different clothing categories
struct FitPreference: Codable, Hashable {
    var category: ClothingCategory
    var fitType: FitType
    
    enum FitType: String, Codable, CaseIterable {
        case tight
        case slim
        case regular
        case relaxed
        case oversized
    }
}

/// Represents fashion seasons
enum Season: String, Codable, CaseIterable {
    case spring
    case summer
    case fall
    case winter
} 