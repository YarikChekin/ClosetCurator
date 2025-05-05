import XCTest
import SwiftData
import WeatherKit
@testable import ClosetCurator

final class WeatherIntegrationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var weatherService: WeatherService!
    
    override func setUp() {
        super.setUp()
        // Set up an in-memory SwiftData container for testing
        do {
            let schema = Schema([
                ClothingItem.self,
                Outfit.self,
                StylePreference.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
            weatherService = WeatherService()
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        weatherService = nil
        super.tearDown()
    }
    
    func testWeatherBasedClothingRecommendations() async throws {
        // Create test clothing items with various properties
        let testItems = createWeatherSensitiveItems()
        testItems.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        // Test cold weather recommendations
        let coldWeather = createMockWeather(temperature: 5, condition: .clear)
        let coldWeatherTags = weatherService.getWeatherTags(for: coldWeather)
        
        // Get clothing recommendations for cold weather
        let coldRecommendations = testItems.filter { item in
            let itemTags = Set(item.weatherTags)
            return !itemTags.intersection(Set(coldWeatherTags)).isEmpty
        }
        
        // Verify warm clothing is recommended for cold weather
        XCTAssertTrue(coldRecommendations.contains { $0.name == "Wool Sweater" })
        XCTAssertTrue(coldRecommendations.contains { $0.name == "Winter Jacket" })
        XCTAssertFalse(coldRecommendations.contains { $0.name == "Linen Shirt" })
        
        // Test rainy weather recommendations
        let rainyWeather = createMockWeather(temperature: 15, condition: .rain)
        let rainyWeatherTags = weatherService.getWeatherTags(for: rainyWeather)
        
        // Get clothing recommendations for rainy weather
        let rainyRecommendations = testItems.filter { item in
            let itemTags = Set(item.weatherTags)
            return !itemTags.intersection(Set(rainyWeatherTags)).isEmpty
        }
        
        // Verify rain-appropriate clothing is recommended
        XCTAssertTrue(rainyRecommendations.contains { $0.name == "Rain Jacket" })
        XCTAssertTrue(rainyRecommendations.contains { $0.name == "Waterproof Boots" })
        XCTAssertFalse(rainyRecommendations.contains { $0.name == "Linen Shirt" })
    }
    
    func testWeatherBasedOutfitRecommendations() async throws {
        // Create test clothing items
        let items = createWeatherSensitiveItems()
        items.forEach { modelContext.insert($0) }
        
        // Create outfits for different weather conditions
        let outfits = createWeatherSpecificOutfits(with: items)
        outfits.forEach { modelContext.insert($0) }
        
        try modelContext.save()
        
        // Test cold weather outfit recommendations
        let coldWeather = createMockWeather(temperature: 5, condition: .clear)
        let coldWeatherTags = weatherService.getWeatherTags(for: coldWeather)
        
        // Simulate recommendation service with cold weather
        let coldOutfitRecommendations = try await RecommendationService.shared.generateRecommendations(
            outfits: outfits,
            weatherTags: coldWeatherTags,
            stylePreference: nil,
            limit: 2,
            modelContext: modelContext
        )
        
        // Verify cold weather outfits are recommended
        XCTAssertTrue(coldOutfitRecommendations.contains { $0.name == "Winter Outfit" })
        XCTAssertFalse(coldOutfitRecommendations.contains { $0.name == "Summer Outfit" })
        
        // Test warm weather outfit recommendations
        let warmWeather = createMockWeather(temperature: 30, condition: .clear)
        let warmWeatherTags = weatherService.getWeatherTags(for: warmWeather)
        
        // Simulate recommendation service with warm weather
        let warmOutfitRecommendations = try await RecommendationService.shared.generateRecommendations(
            outfits: outfits,
            weatherTags: warmWeatherTags,
            stylePreference: nil,
            limit: 2,
            modelContext: modelContext
        )
        
        // Verify warm weather outfits are recommended
        XCTAssertTrue(warmOutfitRecommendations.contains { $0.name == "Summer Outfit" })
        XCTAssertFalse(warmOutfitRecommendations.contains { $0.name == "Winter Outfit" })
    }
    
    // MARK: - Helper Methods
    
    private func createWeatherSensitiveItems() -> [ClothingItem] {
        return [
            // Cold weather items
            ClothingItem(name: "Wool Sweater", category: .tops, color: "Gray", weatherTags: [.cold, .cool]),
            ClothingItem(name: "Winter Jacket", category: .outerwear, color: "Black", weatherTags: [.cold, .snowy]),
            
            // Warm weather items
            ClothingItem(name: "Linen Shirt", category: .tops, color: "White", weatherTags: [.warm, .hot, .sunny]),
            ClothingItem(name: "Shorts", category: .bottoms, color: "Khaki", weatherTags: [.warm, .hot, .sunny]),
            
            // Rainy weather items
            ClothingItem(name: "Rain Jacket", category: .outerwear, color: "Blue", weatherTags: [.rainy]),
            ClothingItem(name: "Waterproof Boots", category: .footwear, color: "Brown", weatherTags: [.rainy, .snowy])
        ]
    }
    
    private func createWeatherSpecificOutfits(with items: [ClothingItem]) -> [Outfit] {
        // Create a winter outfit
        let winterOutfit = Outfit(name: "Winter Outfit")
        winterOutfit.items = [
            items.first(where: { $0.name == "Wool Sweater" })!,
            items.first(where: { $0.name == "Winter Jacket" })!
        ]
        winterOutfit.weatherTags = [.cold, .cool, .snowy]
        
        // Create a summer outfit
        let summerOutfit = Outfit(name: "Summer Outfit")
        summerOutfit.items = [
            items.first(where: { $0.name == "Linen Shirt" })!,
            items.first(where: { $0.name == "Shorts" })!
        ]
        summerOutfit.weatherTags = [.warm, .hot, .sunny]
        
        // Create a rainy day outfit
        let rainyOutfit = Outfit(name: "Rainy Day Outfit")
        rainyOutfit.items = [
            items.first(where: { $0.name == "Rain Jacket" })!,
            items.first(where: { $0.name == "Waterproof Boots" })!
        ]
        rainyOutfit.weatherTags = [.rainy, .cool]
        
        return [winterOutfit, summerOutfit, rainyOutfit]
    }
    
    // Helper function to create mock weather
    private func createMockWeather(temperature: Double, condition: WeatherCondition) -> Weather {
        // Since we can't directly create a Weather instance, we'll create a mock
        class MockWeather: Weather {
            var currentWeather: CurrentWeather
            var dailyForecast: Forecast<DayWeather>
            var hourlyForecast: Forecast<HourWeather>
            
            init(temperature: Double, condition: WeatherCondition) {
                self.currentWeather = MockCurrentWeather(temperature: temperature, condition: condition)
                self.dailyForecast = Forecast(forecast: [])
                self.hourlyForecast = Forecast(forecast: [])
            }
        }
        
        class MockCurrentWeather: CurrentWeather {
            var temperature: Measurement<UnitTemperature>
            var condition: WeatherCondition
            
            init(temperature: Double, condition: WeatherCondition) {
                self.temperature = Measurement(value: temperature, unit: .celsius)
                self.condition = condition
            }
        }
        
        return MockWeather(temperature: temperature, condition: condition)
    }
} 