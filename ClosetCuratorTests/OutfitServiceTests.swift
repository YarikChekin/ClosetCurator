import XCTest
@testable import ClosetCurator
import CoreData

final class OutfitServiceTests: XCTestCase {
    var service: OutfitService!
    var container: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        // Create in-memory store for testing
        container = NSPersistentContainer(name: "ClosetCurator")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        service = OutfitService(context: container.viewContext)
    }
    
    override func tearDown() {
        container = nil
        service = nil
        super.tearDown()
    }
    
    func testCreateOutfit() throws {
        // Create test clothing items
        let items = createTestClothingItems()
        
        // Create an outfit
        let outfit = try service.createOutfit(
            name: "Test Outfit",
            top: items[0],
            bottom: items[3],
            shoes: items[6],
            weatherTags: [.warm]
        )
        
        // Verify outfit properties
        XCTAssertEqual(outfit.name, "Test Outfit")
        XCTAssertEqual(outfit.top, items[0])
        XCTAssertEqual(outfit.bottom, items[3])
        XCTAssertEqual(outfit.shoes, items[6])
        XCTAssertEqual(outfit.weatherTags, [.warm])
    }
    
    func testFetchOutfits() throws {
        // Create test outfits
        let items = createTestClothingItems()
        let outfit1 = try service.createOutfit(
            name: "Outfit 1",
            top: items[0],
            bottom: items[3],
            shoes: items[6],
            weatherTags: [.warm]
        )
        let outfit2 = try service.createOutfit(
            name: "Outfit 2",
            top: items[1],
            bottom: items[4],
            shoes: items[7],
            weatherTags: [.cold]
        )
        
        // Fetch all outfits
        let outfits = try service.fetchOutfits()
        
        // Verify fetched outfits
        XCTAssertEqual(outfits.count, 2)
        XCTAssertTrue(outfits.contains { $0.name == "Outfit 1" })
        XCTAssertTrue(outfits.contains { $0.name == "Outfit 2" })
    }
    
    func testFetchOutfitsByWeather() throws {
        // Create test outfits
        let items = createTestClothingItems()
        let warmOutfit = try service.createOutfit(
            name: "Warm Outfit",
            top: items[0],
            bottom: items[3],
            shoes: items[6],
            weatherTags: [.warm]
        )
        let coldOutfit = try service.createOutfit(
            name: "Cold Outfit",
            top: items[1],
            bottom: items[4],
            shoes: items[7],
            weatherTags: [.cold]
        )
        
        // Fetch warm outfits
        let warmOutfits = try service.fetchOutfits(matching: [.warm])
        XCTAssertEqual(warmOutfits.count, 1)
        XCTAssertEqual(warmOutfits.first?.name, "Warm Outfit")
        
        // Fetch cold outfits
        let coldOutfits = try service.fetchOutfits(matching: [.cold])
        XCTAssertEqual(coldOutfits.count, 1)
        XCTAssertEqual(coldOutfits.first?.name, "Cold Outfit")
    }
    
    func testDeleteOutfit() throws {
        // Create a test outfit
        let items = createTestClothingItems()
        let outfit = try service.createOutfit(
            name: "Test Outfit",
            top: items[0],
            bottom: items[3],
            shoes: items[6],
            weatherTags: [.warm]
        )
        
        // Delete the outfit
        try service.deleteOutfit(outfit)
        
        // Verify outfit is deleted
        let outfits = try service.fetchOutfits()
        XCTAssertTrue(outfits.isEmpty)
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
} 