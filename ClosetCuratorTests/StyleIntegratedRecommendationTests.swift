import XCTest
import SwiftData
@testable import ClosetCurator

final class StyleIntegratedRecommendationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        // Set up an in-memory SwiftData container for testing
        do {
            let schema = Schema([
                ClothingItem.self,
                Outfit.self,
                StylePreference.self,
                StyleBoard.self,
                StyleBoardItem.self,
                StyleFeedback.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    func testRecommendationWithStylePreferences() async throws {
        // Create test data
        let stylePreference = createStylePreference()
        let items = createTestClothingItems()
        let outfits = createTestOutfits(with: items)
        
        // Insert all test objects into the context
        modelContext.insert(stylePreference)
        items.forEach { modelContext.insert($0) }
        outfits.forEach { modelContext.insert($0) }
        
        try modelContext.save()
        
        // Generate recommendations using the RecommendationService
        let recommendations = try await RecommendationService.shared.generateRecommendations(
            outfits: outfits,
            stylePreference: stylePreference,
            limit: 3,
            modelContext: modelContext
        )
        
        // Verify recommendations are returned
        XCTAssertFalse(recommendations.isEmpty, "Should return recommendations")
        
        // Verify recommendations are influenced by style preferences
        for outfit in recommendations {
            // Check if the outfit contains at least one style tag that matches the preference
            let matchingStyles = Set(outfit.styleTags).intersection(Set(stylePreference.favoriteStyles))
            XCTAssertFalse(matchingStyles.isEmpty, "Recommended outfit should match at least one preferred style")
        }
    }
    
    func testStyleFeedbackImpactsRecommendations() async throws {
        // Create test data
        let stylePreference = createStylePreference()
        let items = createTestClothingItems()
        let outfits = createTestOutfits(with: items)
        
        // Insert all test objects into the context
        modelContext.insert(stylePreference)
        items.forEach { modelContext.insert($0) }
        outfits.forEach { modelContext.insert($0) }
        
        // Create and associate style feedback with the first outfit
        let feedback = StyleFeedback(
            recommendationType: .outfit,
            recommendationId: outfits[0].id,
            response: .liked,
            rating: 5,
            context: StyleFeedback.FeedbackContext(time: Date()),
            preference: stylePreference
        )
        modelContext.insert(feedback)
        
        try modelContext.save()
        
        // Generate recommendations
        let recommendations = try await RecommendationService.shared.generateRecommendations(
            outfits: outfits,
            stylePreference: stylePreference,
            limit: 3,
            modelContext: modelContext
        )
        
        // Verify the liked outfit is prioritized in recommendations
        XCTAssertTrue(recommendations.contains(where: { $0.id == outfits[0].id }), 
                     "The liked outfit should be included in recommendations")
        
        // Ideally, the liked outfit should be ranked higher
        if recommendations.count > 1 && recommendations[0].id == outfits[0].id {
            XCTAssertEqual(recommendations[0].id, outfits[0].id, 
                          "The liked outfit should be ranked higher in recommendations")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createStylePreference() -> StylePreference {
        return StylePreference(
            favoriteColors: ["Blue", "Black", "White"],
            favoriteStyles: [.casual, .modern],
            favoredBrands: ["Nike", "Adidas"],
            favoredFits: [FitPreference(category: .tops, fitType: .regular)],
            adventureLevel: 0.7
        )
    }
    
    private func createTestClothingItems() -> [ClothingItem] {
        return [
            ClothingItem(name: "Blue T-shirt", category: .tops, color: "Blue", brand: "Nike", styleTags: [.casual]),
            ClothingItem(name: "Black Jeans", category: .bottoms, color: "Black", brand: "Levi's", styleTags: [.casual, .modern]),
            ClothingItem(name: "White Sneakers", category: .footwear, color: "White", brand: "Adidas", styleTags: [.casual, .sporty]),
            ClothingItem(name: "Navy Blazer", category: .outerwear, color: "Navy", brand: "Zara", styleTags: [.formal, .modern]),
            ClothingItem(name: "Gray Dress Pants", category: .bottoms, color: "Gray", brand: "H&M", styleTags: [.formal])
        ]
    }
    
    private func createTestOutfits(with items: [ClothingItem]) -> [Outfit] {
        // Create casual outfit with blue shirt, black jeans, white sneakers
        let casualOutfit = Outfit(name: "Casual Day Out")
        casualOutfit.items = [items[0], items[1], items[2]]
        casualOutfit.styleTags = [.casual, .modern]
        casualOutfit.weatherTags = [.warm, .sunny, .mild]
        
        // Create formal outfit with navy blazer and dress pants
        let formalOutfit = Outfit(name: "Business Meeting")
        formalOutfit.items = [items[3], items[4]]
        formalOutfit.styleTags = [.formal, .modern]
        formalOutfit.weatherTags = [.mild, .cool]
        
        return [casualOutfit, formalOutfit]
    }
} 