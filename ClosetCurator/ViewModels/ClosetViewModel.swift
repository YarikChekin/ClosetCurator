import Foundation
import CoreData
import SwiftUI

class ClosetViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let imageService: ImageService
    private let weatherService: WeatherService
    private let recommendationEngine: RecommendationEngine
    
    @Published var clothingItems: [ClothingItem] = []
    @Published var selectedCategory: String?
    @Published var currentWeather: Weather?
    @Published var recommendedOutfits: [Outfit] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
         imageService: ImageService = ImageService(),
         weatherService: WeatherService = WeatherService(),
         recommendationEngine: RecommendationEngine = RecommendationEngine()) {
        self.viewContext = context
        self.imageService = imageService
        self.weatherService = weatherService
        self.recommendationEngine = recommendationEngine
        fetchClothingItems()
    }
    
    func fetchClothingItems() {
        let request = ClothingItem.fetchRequest()
        if let category = selectedCategory {
            request.predicate = NSPredicate(format: "category == %@", category)
        }
        
        do {
            clothingItems = try viewContext.fetch(request)
        } catch {
            self.error = error
        }
    }
    
    func addClothingItem(name: String, category: String, image: UIImage) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let processedImageData = try await imageService.processImage(image)
        
        let newItem = ClothingItem(context: viewContext)
        newItem.name = name
        newItem.category = category
        newItem.imageData = processedImageData
        
        try viewContext.save()
        fetchClothingItems()
    }
    
    func deleteClothingItem(_ item: ClothingItem) {
        viewContext.delete(item)
        try? viewContext.save()
        fetchClothingItems()
    }
    
    func updateWeather() async {
        do {
            currentWeather = try await weatherService.getCurrentWeather()
            updateRecommendations()
        } catch {
            self.error = error
        }
    }
    
    private func updateRecommendations() {
        guard let weather = currentWeather else { return }
        recommendedOutfits = recommendationEngine.getRecommendations(for: weather, from: clothingItems)
    }
    
    func markAsWorn(_ item: ClothingItem) {
        item.lastWorn = Date()
        try? viewContext.save()
    }
} 