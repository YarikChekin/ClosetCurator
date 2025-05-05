import XCTest
@testable import ClosetCurator

final class RecommendationServiceTests: XCTestCase {
    var service: RecommendationService!
    
    override func setUp() {
        super.setUp()
        service = RecommendationService.shared
    }
    
    func testWeatherBasedRecommendations() async throws {
        // Create test outfits with different weather tags
        let outfits = [
            createOutfit(name: "Summer Outfit", weatherTags: [.hot, .warm]),
            createOutfit(name: "Winter Outfit", weatherTags: [.cold, .snowy]),
            createOutfit(name: "Rainy Outfit", weatherTags: [.rainy, .cool])
        ]
        
        // Test hot weather recommendations
        let hotRecommendations = try await service.generateRecommendations(
            outfits: outfits,
            weatherTags: [.hot],
            userPreferences: [.casual]
        )
        
        XCTAssertEqual(hotRecommendations.first?.name, "Summer Outfit")
        
        // Test cold weather recommendations
        let coldRecommendations = try await service.generateRecommendations(
            outfits: outfits,
            weatherTags: [.cold],
            userPreferences: [.casual]
        )
        
        XCTAssertEqual(coldRecommendations.first?.name, "Winter Outfit")
    }
    
    func testStylePreferenceRecommendations() async throws {
        // Create test outfits with different style tags
        let outfits = [
            createOutfit(name: "Casual Outfit", styleTags: [.casual, .modern]),
            createOutfit(name: "Formal Outfit", styleTags: [.formal, .elegant]),
            createOutfit(name: "Business Outfit", styleTags: [.business, .formal])
        ]
        
        // Test casual style recommendations
        let casualRecommendations = try await service.generateRecommendations(
            outfits: outfits,
            weatherTags: [.warm],
            userPreferences: [.casual, .modern]
        )
        
        XCTAssertEqual(casualRecommendations.first?.name, "Casual Outfit")
        
        // Test formal style recommendations
        let formalRecommendations = try await service.generateRecommendations(
            outfits: outfits,
            weatherTags: [.warm],
            userPreferences: [.formal, .elegant]
        )
        
        XCTAssertEqual(formalRecommendations.first?.name, "Formal Outfit")
    }
    
    func testWearCountAndRecencyRecommendations() async throws {
        // Create test outfits with different wear counts and last worn dates
        let outfits = [
            createOutfit(name: "New Outfit", wearCount: 0, lastWorn: nil),
            createOutfit(name: "Recently Worn", wearCount: 5, lastWorn: Date()),
            createOutfit(name: "Old Favorite", wearCount: 10, lastWorn: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
        ]
        
        let recommendations = try await service.generateRecommendations(
            outfits: outfits,
            weatherTags: [.warm],
            userPreferences: [.casual]
        )
        
        // New outfit should be recommended first
        XCTAssertEqual(recommendations.first?.name, "New Outfit")
    }
    
    func testFavoriteBonusRecommendations() async throws {
        // Create test outfits with different favorite statuses
        let outfits = [
            createOutfit(name: "Favorite Outfit", favorite: true),
            createOutfit(name: "Regular Outfit", favorite: false)
        ]
        
        let recommendations = try await service.generateRecommendations(
            outfits: outfits,
            weatherTags: [.warm],
            userPreferences: [.casual]
        )
        
        XCTAssertEqual(recommendations.first?.name, "Favorite Outfit")
    }
    
    // Helper function to create test outfits
    private func createOutfit(
        name: String,
        weatherTags: [WeatherTag] = [],
        styleTags: [StyleTag] = [],
        wearCount: Int = 0,
        lastWorn: Date? = nil,
        favorite: Bool = false
    ) -> Outfit {
        Outfit(
            name: name,
            items: [],
            wearCount: wearCount,
            lastWorn: lastWorn,
            favorite: favorite,
            weatherTags: weatherTags
        )
    }
} 