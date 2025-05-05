import Foundation
import SwiftData

/// StyleBoard represents a collection of inspiration images (vision board)
@Model
final class StyleBoard {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var description: String?
    var season: Season?
    var occasion: Occasion?
    var mood: String?
    
    // Relationship to style preference
    @Relationship var preference: StylePreference?
    
    // Relationship to board items (inspiration images)
    @Relationship(deleteRule: .cascade)
    var items: [StyleBoardItem]
    
    // Extracted style data from ML analysis
    var dominantColors: [String]
    var detectedStyles: [StyleTag]
    var detectedItems: [ClothingCategory: Int] // Counts of detected clothing types
    
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        description: String? = nil,
        season: Season? = nil,
        occasion: Occasion? = nil,
        mood: String? = nil,
        preference: StylePreference? = nil,
        items: [StyleBoardItem] = [],
        dominantColors: [String] = [],
        detectedStyles: [StyleTag] = [],
        detectedItems: [ClothingCategory: Int] = [:]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.description = description
        self.season = season
        self.occasion = occasion
        self.mood = mood
        self.preference = preference
        self.items = items
        self.dominantColors = dominantColors
        self.detectedStyles = detectedStyles
        self.detectedItems = detectedItems
    }
    
    // MARK: - Helper Methods
    
    /// Adds a new inspiration image to the board
    func addInspiration(_ item: StyleBoardItem) {
        items.append(item)
        updatedAt = Date()
    }
    
    /// Removes an inspiration image from the board
    func removeInspiration(_ item: StyleBoardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            updatedAt = Date()
        }
    }
    
    /// Updates the board's style data based on ML analysis
    func updateStyleData(colors: [String], styles: [StyleTag], itemCounts: [ClothingCategory: Int]) {
        dominantColors = colors
        detectedStyles = styles
        detectedItems = itemCounts
        updatedAt = Date()
    }
}

/// Represents a single inspiration image in a StyleBoard
@Model
final class StyleBoardItem {
    var id: UUID
    var addedAt: Date
    var imageURL: URL?
    var sourceURL: URL?
    var sourceType: SourceType
    var notes: String?
    
    // ML-detected attributes
    var detectedColors: [String]
    var detectedStyles: [StyleTag]
    var detectedItems: [ClothingCategory]
    var mlConfidence: Double?
    
    // User tags
    var userTags: [String]
    var userLikeScore: Int? // 1-5 rating
    
    @Relationship var board: StyleBoard?
    
    enum SourceType: String, Codable {
        case screenshot
        case camera
        case photoLibrary
        case web
        case socialMedia
    }
    
    init(
        id: UUID = UUID(),
        addedAt: Date = Date(),
        imageURL: URL? = nil,
        sourceURL: URL? = nil,
        sourceType: SourceType,
        notes: String? = nil,
        detectedColors: [String] = [],
        detectedStyles: [StyleTag] = [],
        detectedItems: [ClothingCategory] = [],
        mlConfidence: Double? = nil,
        userTags: [String] = [],
        userLikeScore: Int? = nil,
        board: StyleBoard? = nil
    ) {
        self.id = id
        self.addedAt = addedAt
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.sourceType = sourceType
        self.notes = notes
        self.detectedColors = detectedColors
        self.detectedStyles = detectedStyles
        self.detectedItems = detectedItems
        self.mlConfidence = mlConfidence
        self.userTags = userTags
        self.userLikeScore = userLikeScore
        self.board = board
    }
}

/// Represents occasions for style boards
enum Occasion: String, Codable, CaseIterable {
    case casual
    case work
    case formal
    case athletic
    case vacation
    case special
} 