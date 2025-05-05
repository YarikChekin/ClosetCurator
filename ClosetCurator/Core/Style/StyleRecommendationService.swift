import Foundation
import SwiftData

/// StyleRecommendationService generates recommendations based on user style preferences
class StyleRecommendationService {
    static let shared = StyleRecommendationService()
    
    private init() {}
    
    /// Generates outfit recommendations based on user preferences and conditions
    func generateOutfitRecommendations(
        preferences: StylePreference,
        weatherConditions: Weather? = nil,
        occasion: Occasion? = nil,
        modelContext: ModelContext
    ) async throws -> [StyleRecommendation] {
        // Fetch all clothing items from database
        let itemsDescriptor = FetchDescriptor<ClothingItem>()
        let allItems = try modelContext.fetch(itemsDescriptor)
        
        // Fetch all outfits from database 
        let outfitsDescriptor = FetchDescriptor<Outfit>()
        let allOutfits = try modelContext.fetch(outfitsDescriptor)
        
        // Filter items based on user preferences
        let preferredItems = filterItemsByPreference(allItems, preferences: preferences)
        
        // Apply weather filters if available
        let weatherFilteredItems = weatherConditions != nil ? 
            filterItemsByWeather(preferredItems, weather: weatherConditions!) : 
            preferredItems
        
        // Group items by category
        let categorizedItems = Dictionary(grouping: weatherFilteredItems) { $0.category }
        
        // Generate outfit recommendations
        var recommendations: [StyleRecommendation] = []
        
        // First, check if there are existing outfits that match the criteria
        for outfit in allOutfits {
            // Skip invalid outfits
            guard outfit.isValid else { continue }
            
            // Check if outfit is suitable for weather
            if let weather = weatherConditions, 
               let temp = weather.temperature,
               !outfit.isSuitableForTemperature(temp) {
                continue
            }
            
            // Check if outfit matches occasion
            if let requiredOccasion = occasion {
                // This would normally check outfit occasion tags
                // For now, just randomly include some outfits
                if Bool.random(in: 0...1) == false {
                    continue
                }
            }
            
            // Calculate confidence based on how well it matches preferences
            let confidence = calculateOutfitConfidence(outfit, preferences: preferences)
            
            // Calculate adventure level
            let adventureLevel = calculateAdventureLevel(outfit, preferences: preferences)
            
            // If confidence is high enough, add to recommendations
            if confidence > 0.6 {
                recommendations.append(StyleRecommendation(
                    id: UUID(),
                    type: .outfit,
                    targetId: outfit.id,
                    confidence: confidence,
                    adventureLevel: adventureLevel,
                    reason: generateRecommendationReason(outfit, preferences: preferences),
                    basedOn: outfit.items.map { $0.id },
                    category: nil,
                    style: nil,
                    color: nil,
                    brand: nil,
                    forOccasion: occasion,
                    forSeason: determineSeason(),
                    forWeather: weatherConditions
                ))
            }
        }
        
        // Generate new outfit combinations if necessary
        if recommendations.count < 5 && categorizedItems.count >= 2 {
            // Create new outfit combinations
            let newRecommendations = try generateNewOutfitCombinations(
                categorizedItems: categorizedItems,
                preferences: preferences,
                occasion: occasion,
                weather: weatherConditions,
                limit: 5 - recommendations.count
            )
            
            recommendations.append(contentsOf: newRecommendations)
        }
        
        // Sort by confidence
        return recommendations.sorted { $0.confidence > $1.confidence }
    }
    
    /// Generates new item recommendations based on style preferences and vision boards
    func generateItemRecommendations(
        preferences: StylePreference,
        styleBoards: [StyleBoard] = [],
        modelContext: ModelContext
    ) async throws -> [StyleRecommendation] {
        var recommendations: [StyleRecommendation] = []
        
        // Calculate user's style profile from preferences and vision boards
        var preferredColors = preferences.favoriteColors
        var preferredStyles = preferences.favoriteStyles
        var preferredBrands = preferences.favoredBrands
        
        // Enhance with vision board data
        for board in styleBoards {
            preferredColors.append(contentsOf: board.dominantColors)
            preferredStyles.append(contentsOf: board.detectedStyles)
        }
        
        // Generate brand recommendations
        for brand in generateBrandRecommendations(
            basedOn: preferredBrands,
            styles: preferredStyles
        ) {
            recommendations.append(StyleRecommendation(
                id: UUID(),
                type: .brand,
                targetId: nil,
                confidence: Double.random(in: 0.7...0.95),
                adventureLevel: Double.random(in: 0.2...0.8),
                reason: "Based on your style preferences and similar brands you like",
                basedOn: nil,
                category: nil,
                style: nil,
                color: nil,
                brand: brand,
                forOccasion: nil,
                forSeason: determineSeason(),
                forWeather: nil
            ))
        }
        
        // Generate style recommendations
        for style in generateStyleRecommendations(basedOn: preferredStyles) {
            recommendations.append(StyleRecommendation(
                id: UUID(),
                type: .style,
                targetId: nil,
                confidence: Double.random(in: 0.7...0.95),
                adventureLevel: Double.random(in: 0.3...0.9),
                reason: "This style matches elements from your vision boards and complements your current preferences",
                basedOn: nil,
                category: nil,
                style: style,
                color: nil,
                brand: nil,
                forOccasion: nil,
                forSeason: determineSeason(),
                forWeather: nil
            ))
        }
        
        // Generate specific item recommendations
        for category in ClothingCategory.allCases {
            // Only recommend some categories
            if Bool.random(in: 0...1) == false {
                continue
            }
            
            // Pick a random style and color combination
            let style = preferredStyles.randomElement() ?? StyleTag.allCases.randomElement()!
            let color = preferredColors.randomElement() ?? "Black"
            
            recommendations.append(StyleRecommendation(
                id: UUID(),
                type: .item,
                targetId: nil,
                confidence: Double.random(in: 0.65...0.9),
                adventureLevel: Double.random(in: 0.2...preferences.adventureLevel * 1.3),
                reason: "This \(color) \(category.rawValue) in \(style.rawValue) style would complement your current wardrobe",
                basedOn: nil,
                category: category,
                style: style,
                color: color,
                brand: preferredBrands.randomElement(),
                forOccasion: nil,
                forSeason: determineSeason(),
                forWeather: nil
            ))
        }
        
        return recommendations.shuffled().prefix(10).sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Helper Methods
    
    private func filterItemsByPreference(_ items: [ClothingItem], preferences: StylePreference) -> [ClothingItem] {
        // In a real implementation, this would apply sophisticated filtering based on preferences
        // For now, just return all items
        return items
    }
    
    private func filterItemsByWeather(_ items: [ClothingItem], weather: Weather) -> [ClothingItem] {
        // Filter items based on weather conditions
        guard let temperature = weather.temperature else { return items }
        
        return items.filter { item in
            item.isSuitableForTemperature(temperature)
        }
    }
    
    private func calculateOutfitConfidence(_ outfit: Outfit, preferences: StylePreference) -> Double {
        // Calculate how well this outfit matches the user's preferences
        // This would normally use a more sophisticated algorithm
        return Double.random(in: 0.6...0.95)
    }
    
    private func calculateAdventureLevel(_ outfit: Outfit, preferences: StylePreference) -> Double {
        // Calculate how far this outfit is from the user's comfort zone
        // This would normally use a more sophisticated algorithm
        return min(preferences.adventureLevel * 1.2, 1.0)
    }
    
    private func generateRecommendationReason(_ outfit: Outfit, preferences: StylePreference) -> String {
        // Generate an explanation for why this outfit is recommended
        let reasons = [
            "This outfit matches your style preferences",
            "This combination works well for the current weather",
            "These colors complement each other well",
            "This is a versatile outfit that can be dressed up or down",
            "This outfit has a similar vibe to your vision boards"
        ]
        
        return reasons.randomElement()!
    }
    
    private func generateNewOutfitCombinations(
        categorizedItems: [ClothingCategory: [ClothingItem]],
        preferences: StylePreference,
        occasion: Occasion?,
        weather: Weather?,
        limit: Int
    ) throws -> [StyleRecommendation] {
        var recommendations: [StyleRecommendation] = []
        
        // Ensure we have tops and bottoms (or dresses)
        guard (categorizedItems[.tops]?.isEmpty == false && categorizedItems[.bottoms]?.isEmpty == false)
                || categorizedItems[.dresses]?.isEmpty == false else {
            return []
        }
        
        // Generate some outfit combinations
        for _ in 0..<min(limit, 3) {
            // Either use a dress, or a top + bottom combination
            let useTopBottom = categorizedItems[.dresses]?.isEmpty == true ||
                              (categorizedItems[.tops]?.isEmpty == false && 
                               categorizedItems[.bottoms]?.isEmpty == false && 
                               Bool.random(in: 0...1))
            
            var outfitItems: [ClothingItem] = []
            var outfitItemIds: [UUID] = []
            
            if useTopBottom {
                // Add a top
                if let tops = categorizedItems[.tops], !tops.isEmpty {
                    let randomTop = tops.randomElement()!
                    outfitItems.append(randomTop)
                    outfitItemIds.append(randomTop.id)
                }
                
                // Add a bottom
                if let bottoms = categorizedItems[.bottoms], !bottoms.isEmpty {
                    let randomBottom = bottoms.randomElement()!
                    outfitItems.append(randomBottom)
                    outfitItemIds.append(randomBottom.id)
                }
            } else {
                // Add a dress
                if let dresses = categorizedItems[.dresses], !dresses.isEmpty {
                    let randomDress = dresses.randomElement()!
                    outfitItems.append(randomDress)
                    outfitItemIds.append(randomDress.id)
                }
            }
            
            // Optionally add shoes
            if let shoes = categorizedItems[.shoes], !shoes.isEmpty && Bool.random(in: 0...1) {
                let randomShoes = shoes.randomElement()!
                outfitItems.append(randomShoes)
                outfitItemIds.append(randomShoes.id)
            }
            
            // Optionally add accessories
            if let accessories = categorizedItems[.accessories], !accessories.isEmpty && Bool.random(in: 0...1) {
                let randomAccessory = accessories.randomElement()!
                outfitItems.append(randomAccessory)
                outfitItemIds.append(randomAccessory.id)
            }
            
            // Optionally add outerwear
            if let outerwear = categorizedItems[.outerwear], !outerwear.isEmpty && Bool.random(in: 0...1) {
                let randomOuterwear = outerwear.randomElement()!
                outfitItems.append(randomOuterwear)
                outfitItemIds.append(randomOuterwear.id)
            }
            
            // Calculate confidence and adventure level
            let confidence = Double.random(in: 0.65...0.9)
            let adventureLevel = Double.random(in: 0.2...preferences.adventureLevel * 1.2)
            
            // Generate a reason for this combination
            let reason = generateOutfitCombinationReason(outfitItems, occasion: occasion, weather: weather)
            
            // Create recommendation
            recommendations.append(StyleRecommendation(
                id: UUID(),
                type: .outfit,
                targetId: nil, // This is a new combination, not an existing outfit
                confidence: confidence,
                adventureLevel: adventureLevel,
                reason: reason,
                basedOn: outfitItemIds,
                category: nil,
                style: nil,
                color: nil,
                brand: nil,
                forOccasion: occasion,
                forSeason: determineSeason(),
                forWeather: weather
            ))
        }
        
        return recommendations
    }
    
    private func generateOutfitCombinationReason(
        _ items: [ClothingItem],
        occasion: Occasion?,
        weather: Weather?
    ) -> String {
        // Generate an explanation for this outfit combination
        let baseReasons = [
            "These pieces complement each other well",
            "This combination creates a balanced silhouette",
            "These colors work well together",
            "This outfit has a cohesive style"
        ]
        
        var reason = baseReasons.randomElement()!
        
        // Add occasion-specific reason
        if let occasion = occasion {
            let occasionReasons = [
                "Perfect for \(occasion.rawValue) occasions",
                "Suitable for \(occasion.rawValue) events",
                "Works well for \(occasion.rawValue) settings"
            ]
            reason += " and is " + occasionReasons.randomElement()!
        }
        
        // Add weather-specific reason
        if let weather = weather, let temperature = weather.temperature {
            let temperatureDescription = temperature < 10 ? "cold" :
                                        temperature < 18 ? "cool" :
                                        temperature < 25 ? "mild" : "warm"
            
            let weatherReasons = [
                "Appropriate for \(temperatureDescription) weather",
                "Comfortable in \(temperatureDescription) temperatures",
                "Suitable for \(temperatureDescription) conditions"
            ]
            reason += ". " + weatherReasons.randomElement()!
        }
        
        return reason
    }
    
    private func generateBrandRecommendations(basedOn brands: [String], styles: [StyleTag]) -> [String] {
        // This would normally use a database of related brands
        // For now, just return some mock recommendations
        let mockBrands = [
            "Everlane",
            "Madewell",
            "Reformation",
            "Uniqlo",
            "Zara",
            "H&M",
            "COS",
            "& Other Stories",
            "Urban Outfitters",
            "Anthropologie"
        ]
        
        return Array(mockBrands.shuffled().prefix(3))
    }
    
    private func generateStyleRecommendations(basedOn styles: [StyleTag]) -> [StyleTag] {
        // This would normally identify complementary or trending styles
        // For now, return some styles that aren't in the input
        var recommendations: [StyleTag] = []
        let allStyles = Set(StyleTag.allCases)
        let currentStyles = Set(styles)
        let availableStyles = allStyles.subtracting(currentStyles)
        
        return Array(availableStyles.shuffled().prefix(2))
    }
    
    private func determineSeason() -> Season {
        // In a real app, this would use the current date
        // For now, just return a random season
        return Season.allCases.randomElement()!
    }
} 