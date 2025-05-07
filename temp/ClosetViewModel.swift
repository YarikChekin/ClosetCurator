import Foundation
import CoreData
import SwiftUI
import WeatherKit
import CoreLocation

@MainActor
class ClosetViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    private let weatherService: WeatherService
    private let locationManager: CLLocationManager
    private let imageService: ImageService
    private let recommendationEngine: RecommendationEngine
    
    @Published var clothingItems: [ClothingItem] = []
    @Published var outfits: [Outfit] = []
    @Published var recommendedOutfits: [Outfit] = []
    @Published var currentWeather: CurrentWeather?
    @Published var isLoading = false
    @Published var error: String?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.weatherService = WeatherService.shared
        self.locationManager = CLLocationManager()
        self.imageService = ImageService()
        self.recommendationEngine = RecommendationEngine()
        
        setupLocationManager()
        fetchClothingItems()
        fetchOutfits()
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchClothingItems() {
        let request = ClothingItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClothingItem.dateAdded, ascending: false)]
        
        do {
            clothingItems = try context.fetch(request)
        } catch {
            self.error = "Failed to fetch clothing items: \(error.localizedDescription)"
        }
    }
    
    func fetchOutfits() {
        let request = Outfit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Outfit.dateCreated, ascending: false)]
        
        do {
            outfits = try context.fetch(request)
        } catch {
            self.error = "Failed to fetch outfits: \(error.localizedDescription)"
        }
    }
    
    func addClothingItem(name: String, category: ClothingCategory, imageData: Data) async throws {
        let processedImageData = try await imageService.processImage(imageData)
        
        let item = ClothingItem(context: context)
        item.id = UUID()
        item.name = name
        item.category = category.rawValue
        item.imageData = processedImageData
        item.dateAdded = Date()
        
        try context.save()
        fetchClothingItems()
    }
    
    func deleteClothingItem(_ item: ClothingItem) {
        context.delete(item)
        
        do {
            try context.save()
            fetchClothingItems()
            fetchOutfits()
        } catch {
            self.error = "Failed to delete item: \(error.localizedDescription)"
        }
    }
    
    func createOutfit(name: String, items: [ClothingItem], weatherTags: [WeatherTag]) throws {
        let outfit = Outfit(context: context)
        outfit.id = UUID()
        outfit.name = name
        outfit.dateCreated = Date()
        outfit.items = NSSet(array: items)
        outfit.weatherTags = weatherTags.map { $0.rawValue }
        
        try context.save()
        fetchOutfits()
    }
    
    func deleteOutfit(_ outfit: Outfit) {
        context.delete(outfit)
        
        do {
            try context.save()
            fetchOutfits()
        } catch {
            self.error = "Failed to delete outfit: \(error.localizedDescription)"
        }
    }
    
    func markAsWorn(_ outfit: Outfit) {
        outfit.lastWorn = Date()
        outfit.items?.allObjects.forEach { item in
            (item as? ClothingItem)?.lastWorn = Date()
        }
        
        do {
            try context.save()
            fetchOutfits()
        } catch {
            self.error = "Failed to update outfit: \(error.localizedDescription)"
        }
    }
    
    func updateWeather() async {
        isLoading = true
        error = nil
        
        guard let location = locationManager.location else {
            error = "Location not available"
            isLoading = false
            return
        }
        
        do {
            currentWeather = try await weatherService.weather(for: location).currentWeather
            updateRecommendations()
        } catch {
            self.error = "Failed to fetch weather: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func updateRecommendations() {
        guard let weather = currentWeather else { return }
        
        let temperatureTags = WeatherTag.forTemperature(weather.temperature.value)
        let conditionTags = WeatherTag.forWeatherCondition(weather.condition.description)
        let weatherTags = temperatureTags + conditionTags
        
        recommendedOutfits = recommendationEngine.recommendOutfits(from: outfits,
                                                                 for: weatherTags,
                                                                 limit: 5)
    }
} 