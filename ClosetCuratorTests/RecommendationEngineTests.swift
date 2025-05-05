import XCTest
@testable import ClosetCurator
import CoreML

final class RecommendationEngineTests: XCTestCase {
    var engine: RecommendationEngine!
    var mockWeatherService: MockWeatherService!
    
    override func setUp() {
        super.setUp()
        mockWeatherService = MockWeatherService()
        engine = RecommendationEngine(weatherService: mockWeatherService)
    }
    
    func testOutfitRecommendation() async throws {
        // Create test clothing items
        let items = createTestClothingItems()
        
        // Set mock weather
        mockWeatherService.mockWeather = createMockWeather(temperature: 20, condition: .clear)
        
        // Get recommendations
        let recommendations = try await engine.getRecommendations(for: items)
        
        // Verify recommendations
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertEqual(recommendations.count, 3) // Default number of recommendations
        
        // Verify each recommendation has required items
        for outfit in recommendations {
            XCTAssertNotNil(outfit.top)
            XCTAssertNotNil(outfit.bottom)
            XCTAssertNotNil(outfit.shoes)
        }
    }
    
    func testWeatherBasedRecommendations() async throws {
        // Create test clothing items
        let items = createTestClothingItems()
        
        // Test cold weather recommendations
        mockWeatherService.mockWeather = createMockWeather(temperature: 5, condition: .clear)
        let coldRecommendations = try await engine.getRecommendations(for: items)
        XCTAssertTrue(coldRecommendations.allSatisfy { $0.top?.weatherTags.contains(.cold) ?? false })
        
        // Test rainy weather recommendations
        mockWeatherService.mockWeather = createMockWeather(temperature: 15, condition: .rain)
        let rainyRecommendations = try await engine.getRecommendations(for: items)
        XCTAssertTrue(rainyRecommendations.allSatisfy { $0.top?.weatherTags.contains(.rainy) ?? false })
    }
    
    // Helper function to create test clothing items
    private func createTestClothingItems() -> [ClothingItem] {
        let tops = [
            ClothingItem(name: "T-Shirt", category: .top, weatherTags: [.warm]),
            ClothingItem(name: "Sweater", category: .top, weatherTags: [.cold]),
            ClothingItem(name: "Rain Jacket", category: .top, weatherTags: [.rainy])
        ]
        
        let bottoms = [
            ClothingItem(name: "Jeans", category: .bottom, weatherTags: [.cool, .warm]),
            ClothingItem(name: "Shorts", category: .bottom, weatherTags: [.hot]),
            ClothingItem(name: "Rain Pants", category: .bottom, weatherTags: [.rainy])
        ]
        
        let shoes = [
            ClothingItem(name: "Sneakers", category: .shoes, weatherTags: [.warm]),
            ClothingItem(name: "Boots", category: .shoes, weatherTags: [.cold, .snowy]),
            ClothingItem(name: "Rain Boots", category: .shoes, weatherTags: [.rainy])
        ]
        
        return tops + bottoms + shoes
    }
    
    // Helper function to create mock weather
    private func createMockWeather(temperature: Double, condition: WeatherCondition) -> Weather {
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

// Mock WeatherService for testing
class MockWeatherService: WeatherService {
    var mockWeather: Weather?
    
    override func getCurrentWeather() async throws -> Weather {
        guard let weather = mockWeather else {
            throw WeatherError.locationNotAvailable
        }
        return weather
    }
} 