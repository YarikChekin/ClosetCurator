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
    var seasonality: Set<Season>
    var styleTags: Set<String>
    var wearCount: Int
    var lastWorn: Date?
    var favorite: Bool
    var mlConfidence: Double?
    
    // Weather-related properties
    var minTemperature: Double?
    var maxTemperature: Double?
    var weatherConditions: Set<WeatherCondition>
    
    var weatherTags: [WeatherTag]
    
    enum Category: String, Codable, CaseIterable {
        case tops = "Tops"
        case bottoms = "Bottoms"
        case dresses = "Dresses"
        case outerwear = "Outerwear"
        case shoes = "Shoes"
        case accessories = "Accessories"
    }
    
    enum Season: String, Codable, CaseIterable {
        case spring, summer, fall, winter
    }
    
    enum WeatherCondition: String, Codable, CaseIterable {
        case sunny, rainy, cloudy, snowy, windy
    }
    
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
        seasonality: Set<Season> = [],
        styleTags: Set<String> = [],
        wearCount: Int = 0,
        lastWorn: Date? = nil,
        favorite: Bool = false,
        mlConfidence: Double? = nil,
        minTemperature: Double? = nil,
        maxTemperature: Double? = nil,
        weatherConditions: Set<WeatherCondition> = [],
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
        self.seasonality = seasonality
        self.styleTags = styleTags
        self.wearCount = wearCount
        self.lastWorn = lastWorn
        self.favorite = favorite
        self.mlConfidence = mlConfidence
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
        self.weatherConditions = weatherConditions
        self.weatherTags = weatherTags
    }
    
    // MARK: - Weather Compatibility
    
    func isSuitableForTemperature(_ temperature: Double) -> Bool {
        guard let range = temperatureRange else { return true }
        return range.contains(temperature)
    }
    
    func isSuitableForWeather(_ conditions: Set<WeatherCondition>) -> Bool {
        guard !weatherConditions.isEmpty else { return true }
        return !conditions.isDisjoint(with: weatherConditions)
    }
    
    // MARK: - ML Analysis
    
    func updateMLConfidence(_ confidence: Double) {
        self.mlConfidence = confidence
    }
    
    // MARK: - Usage Tracking
    
    func incrementWearCount() {
        wearCount += 1
        lastWorn = Date()
    }
}

enum ClothingCategory: String, Codable {
    case tops
    case bottoms
    case dresses
    case outerwear
    case shoes
    case accessories
}

enum WeatherTag: String, Codable {
    case hot
    case warm
    case cool
    case cold
    case rainy
    case snowy
}

enum StyleTag: String, Codable {
    case casual
    case formal
    case business
    case sporty
    case elegant
    case vintage
    case modern
} 