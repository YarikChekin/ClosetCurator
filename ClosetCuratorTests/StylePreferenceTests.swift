import XCTest
import SwiftData
@testable import ClosetCurator

final class StylePreferenceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        // Set up an in-memory SwiftData container for testing
        do {
            let schema = Schema([StylePreference.self, StyleBoard.self, StyleBoardItem.self, StyleFeedback.self])
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
    
    func testStylePreferenceCreation() throws {
        // Create a test style preference
        let stylePreference = StylePreference(
            favoriteColors: ["Blue", "Black"],
            favoriteStyles: [.casual, .modern],
            favoredBrands: ["Nike", "Adidas"],
            favoredFits: [FitPreference(category: .tops, fitType: .regular)],
            adventureLevel: 0.7
        )
        
        // Insert into the context
        modelContext.insert(stylePreference)
        try modelContext.save()
        
        // Fetch the saved preference
        let descriptor = FetchDescriptor<StylePreference>()
        let savedPreferences = try modelContext.fetch(descriptor)
        
        // Verify
        XCTAssertEqual(savedPreferences.count, 1)
        XCTAssertEqual(savedPreferences.first?.favoriteColors, ["Blue", "Black"])
        XCTAssertEqual(savedPreferences.first?.favoriteStyles, [.casual, .modern])
        XCTAssertEqual(savedPreferences.first?.favoredBrands, ["Nike", "Adidas"])
        XCTAssertEqual(savedPreferences.first?.adventureLevel, 0.7)
    }
    
    func testStylePreferenceUpdate() throws {
        // Create a test style preference
        let stylePreference = StylePreference(
            favoriteColors: ["Red"],
            favoriteStyles: [.formal],
            adventureLevel: 0.3
        )
        
        // Insert into the context
        modelContext.insert(stylePreference)
        try modelContext.save()
        
        // Update the preference
        stylePreference.updatePreferences(
            newColors: ["Blue", "Green"],
            newStyles: [.casual, .sporty]
        )
        stylePreference.updateAdventureLevel(newLevel: 0.8)
        try modelContext.save()
        
        // Fetch the saved preference
        let descriptor = FetchDescriptor<StylePreference>()
        let savedPreferences = try modelContext.fetch(descriptor)
        
        // Verify
        XCTAssertEqual(savedPreferences.count, 1)
        
        // Check that frequencies are considered - the original favorites should still be present
        // but the new ones should be added, with the order reflecting frequency/recency
        XCTAssertTrue(savedPreferences.first?.favoriteColors.contains("Blue") == true)
        XCTAssertTrue(savedPreferences.first?.favoriteColors.contains("Green") == true)
        XCTAssertTrue(savedPreferences.first?.favoriteColors.contains("Red") == true)
        
        XCTAssertTrue(savedPreferences.first?.favoriteStyles.contains(.casual) == true)
        XCTAssertTrue(savedPreferences.first?.favoriteStyles.contains(.sporty) == true)
        XCTAssertTrue(savedPreferences.first?.favoriteStyles.contains(.formal) == true)
        
        // Adventure level should be weighted update (not direct replacement)
        let updatedLevel = savedPreferences.first?.adventureLevel ?? 0
        XCTAssertGreaterThan(updatedLevel, 0.3)
        XCTAssertLessThan(updatedLevel, 0.8) // Should be weighted between old and new
    }
    
    func testStyleBoardRelationship() throws {
        // Create a style preference
        let stylePreference = StylePreference(
            favoriteColors: ["Blue"],
            favoriteStyles: [.casual]
        )
        modelContext.insert(stylePreference)
        
        // Create a style board
        let styleBoard = StyleBoard(
            name: "Summer Vibes",
            occasion: .casual,
            preference: stylePreference
        )
        modelContext.insert(styleBoard)
        
        // Create an item
        let boardItem = StyleBoardItem(
            sourceType: .photoLibrary,
            board: styleBoard
        )
        modelContext.insert(boardItem)
        
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<StylePreference>()
        let savedPreferences = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(savedPreferences.count, 1)
        XCTAssertEqual(savedPreferences.first?.styleBoards?.count, 1)
        XCTAssertEqual(savedPreferences.first?.styleBoards?.first?.name, "Summer Vibes")
        XCTAssertEqual(savedPreferences.first?.styleBoards?.first?.items.count, 1)
    }
    
    func testStyleFeedbackRelationship() throws {
        // Create a style preference
        let stylePreference = StylePreference(
            favoriteColors: ["Blue"],
            favoriteStyles: [.casual]
        )
        modelContext.insert(stylePreference)
        
        // Create feedback
        let feedback = StyleFeedback(
            recommendationType: .outfit,
            recommendationId: UUID(),
            response: .liked,
            rating: 5,
            context: StyleFeedback.FeedbackContext(time: Date()),
            preference: stylePreference
        )
        modelContext.insert(feedback)
        
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<StylePreference>()
        let savedPreferences = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(savedPreferences.count, 1)
        XCTAssertEqual(savedPreferences.first?.styleFeedback?.count, 1)
        XCTAssertEqual(savedPreferences.first?.styleFeedback?.first?.response, .liked)
        XCTAssertEqual(savedPreferences.first?.styleFeedback?.first?.rating, 5)
    }
} 