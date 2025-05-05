import XCTest
import SwiftData
@testable import ClosetCurator

final class StyleBoardTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        // Set up an in-memory SwiftData container for testing
        do {
            let schema = Schema([
                StylePreference.self,
                StyleBoard.self,
                StyleBoardItem.self
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
    
    func testStyleBoardCreation() throws {
        // Create a style preference
        let stylePreference = StylePreference(
            favoriteColors: ["Blue", "Black"],
            favoriteStyles: [.casual, .modern]
        )
        modelContext.insert(stylePreference)
        
        // Create a style board
        let styleBoard = StyleBoard(
            name: "Spring Collection",
            occasion: .casual,
            preference: stylePreference
        )
        styleBoard.dominantColors = ["Green", "Yellow"]
        styleBoard.detectedStyles = [.bohemian, .natural]
        modelContext.insert(styleBoard)
        
        try modelContext.save()
        
        // Fetch the saved board
        let descriptor = FetchDescriptor<StyleBoard>()
        let savedBoards = try modelContext.fetch(descriptor)
        
        // Verify
        XCTAssertEqual(savedBoards.count, 1)
        XCTAssertEqual(savedBoards.first?.name, "Spring Collection")
        XCTAssertEqual(savedBoards.first?.occasion, .casual)
        XCTAssertEqual(savedBoards.first?.dominantColors, ["Green", "Yellow"])
        XCTAssertEqual(savedBoards.first?.detectedStyles, [.bohemian, .natural])
    }
    
    func testStyleBoardItemRelationship() throws {
        // Create a style preference
        let stylePreference = StylePreference(
            favoriteColors: ["Blue", "Black"],
            favoriteStyles: [.casual, .modern]
        )
        modelContext.insert(stylePreference)
        
        // Create a style board
        let styleBoard = StyleBoard(
            name: "Winter Inspiration",
            occasion: .formal,
            preference: stylePreference
        )
        modelContext.insert(styleBoard)
        
        // Create board items
        let item1 = StyleBoardItem(
            sourceType: .photoLibrary,
            sourcePath: "path/to/image1.jpg",
            dominantColors: ["Gray", "White"],
            detectedStyles: [.minimal, .classic],
            board: styleBoard
        )
        
        let item2 = StyleBoardItem(
            sourceType: .screenshot,
            sourcePath: "path/to/image2.jpg",
            dominantColors: ["Black", "Silver"],
            detectedStyles: [.formal, .minimal],
            board: styleBoard
        )
        
        modelContext.insert(item1)
        modelContext.insert(item2)
        
        try modelContext.save()
        
        // Fetch the saved board
        let descriptor = FetchDescriptor<StyleBoard>()
        let savedBoards = try modelContext.fetch(descriptor)
        
        // Verify
        XCTAssertEqual(savedBoards.count, 1)
        XCTAssertEqual(savedBoards.first?.items.count, 2)
        
        // Verify items are correctly associated
        let items = savedBoards.first!.items
        XCTAssertTrue(items.contains { $0.sourceType == .photoLibrary })
        XCTAssertTrue(items.contains { $0.sourceType == .screenshot })
    }
    
    func testStyleBoardInfluencesPreferences() throws {
        // Create a style preference with initial preferences
        let stylePreference = StylePreference(
            favoriteColors: ["Blue", "Black"],
            favoriteStyles: [.casual, .modern]
        )
        modelContext.insert(stylePreference)
        
        // Create a style board with different styles and colors
        let styleBoard = StyleBoard(
            name: "New Inspiration",
            occasion: .casual,
            preference: stylePreference
        )
        styleBoard.dominantColors = ["Red", "Orange"]
        styleBoard.detectedStyles = [.vintage, .bohemian]
        modelContext.insert(styleBoard)
        
        // Create board items with strong style signals
        let item1 = StyleBoardItem(
            sourceType: .photoLibrary,
            dominantColors: ["Red", "Brown"],
            detectedStyles: [.vintage, .retro],
            board: styleBoard
        )
        
        let item2 = StyleBoardItem(
            sourceType: .screenshot,
            dominantColors: ["Orange", "Yellow"],
            detectedStyles: [.bohemian, .artistic],
            board: styleBoard
        )
        
        modelContext.insert(item1)
        modelContext.insert(item2)
        
        try modelContext.save()
        
        // Simulate the preference learning mechanism
        stylePreference.updatePreferences(
            newColors: styleBoard.dominantColors,
            newStyles: styleBoard.detectedStyles
        )
        
        // Add more influence from items
        for item in styleBoard.items {
            stylePreference.updatePreferences(
                newColors: item.dominantColors,
                newStyles: item.detectedStyles
            )
        }
        
        try modelContext.save()
        
        // Fetch the updated preference
        let descriptor = FetchDescriptor<StylePreference>()
        let savedPreferences = try modelContext.fetch(descriptor)
        
        // Verify preferences have been influenced by the style board
        XCTAssertTrue(savedPreferences.first!.favoriteColors.contains("Red"))
        XCTAssertTrue(savedPreferences.first!.favoriteColors.contains("Orange"))
        XCTAssertTrue(savedPreferences.first!.favoriteStyles.contains(.vintage))
        XCTAssertTrue(savedPreferences.first!.favoriteStyles.contains(.bohemian))
        
        // Original preferences should still be present
        XCTAssertTrue(savedPreferences.first!.favoriteColors.contains("Blue"))
        XCTAssertTrue(savedPreferences.first!.favoriteStyles.contains(.casual))
    }
} 