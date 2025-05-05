import Foundation
import SwiftData

@Model
final class Outfit {
    var id: UUID
    var name: String
    var items: [ClothingItem]
    var dateCreated: Date
    var lastWorn: Date?
    var wearCount: Int
    var favorite: Bool
    var notes: String?
    var seasonality: Set<ClothingItem.Season>
    var styleTags: Set<String>
    var temperatureRange: ClosedRange<Double>?
    var weatherConditions: Set<ClothingItem.WeatherCondition>
    var userRating: Int?
    var aiConfidence: Double?
    var rating: Int?
    var weatherTags: [WeatherTag]
    
    init(
        id: UUID = UUID(),
        name: String,
        items: [ClothingItem],
        dateCreated: Date = Date(),
        lastWorn: Date? = nil,
        wearCount: Int = 0,
        favorite: Bool = false,
        notes: String? = nil,
        seasonality: Set<ClothingItem.Season> = [],
        styleTags: Set<String> = [],
        temperatureRange: ClosedRange<Double>? = nil,
        weatherConditions: Set<ClothingItem.WeatherCondition> = [],
        userRating: Int? = nil,
        aiConfidence: Double? = nil,
        rating: Int? = nil,
        weatherTags: [WeatherTag] = []
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.dateCreated = dateCreated
        self.lastWorn = lastWorn
        self.wearCount = wearCount
        self.favorite = favorite
        self.notes = notes
        self.seasonality = seasonality
        self.styleTags = styleTags
        self.temperatureRange = temperatureRange
        self.weatherConditions = weatherConditions
        self.userRating = userRating
        self.aiConfidence = aiConfidence
        self.rating = rating
        self.weatherTags = weatherTags
    }
    
    // MARK: - Weather Compatibility
    
    func isSuitableForTemperature(_ temperature: Double) -> Bool {
        guard let range = temperatureRange else { return true }
        return range.contains(temperature)
    }
    
    func isSuitableForWeather(_ conditions: Set<ClothingItem.WeatherCondition>) -> Bool {
        guard !weatherConditions.isEmpty else { return true }
        return !conditions.isDisjoint(with: weatherConditions)
    }
    
    // MARK: - Usage Tracking
    
    func incrementWearCount() {
        wearCount += 1
        lastWorn = Date()
        items.forEach { $0.lastWorn = Date() }
    }
    
    // MARK: - Rating
    
    func updateRating(_ rating: Int) {
        userRating = rating
    }
    
    // MARK: - AI Confidence
    
    func updateAIConfidence(_ confidence: Double) {
        aiConfidence = confidence
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
    
    func markAsWorn() {
        lastWorn = Date()
        items.forEach { $0.lastWorn = Date() }
    }
} 