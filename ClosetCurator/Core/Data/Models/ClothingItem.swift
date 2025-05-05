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
    var temperatureRange: ClosedRange<Double>?
    @Relationship(deleteRule: .cascade) var outfits: [Outfit]?
    var wearCount: Int
    var lastWorn: Date?
    var favorite: Bool
    var mlConfidence: Double?
    
    // Weather-related properties
    var minTemperature: Double?
    var maxTemperature: Double?
    var weatherTags: [WeatherTag]
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
        temperatureRange: ClosedRange<Double>? = nil,
        outfits: [Outfit]? = nil,
        wearCount: Int = 0,
        lastWorn: Date? = nil,
        favorite: Bool = false,
        mlConfidence: Double? = nil,
        minTemperature: Double? = nil,
        maxTemperature: Double? = nil,
        weatherTags: [WeatherTag] = [],
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
        self.temperatureRange = temperatureRange
        self.outfits = outfits
        self.wearCount = wearCount
        self.lastWorn = lastWorn
        self.favorite = favorite
        self.mlConfidence = mlConfidence
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
        self.weatherTags = weatherTags
        self.styleTags = styleTags
    }
    
    // MARK: - Weather Compatibility
    
    func isSuitableForTemperature(_ temperature: Double) -> Bool {
        guard let minTemp = minTemperature, let maxTemp = maxTemperature else { return true }
        return temperature >= minTemp && temperature <= maxTemp
    }
    
    // MARK: - Usage Tracking
    
    func markAsWorn() {
        wearCount += 1
        lastWorn = Date()
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

enum WeatherTag: String, Codable, CaseIterable {
    case hot
    case warm
    case cool
    case cold
    case rainy
    case snowy
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