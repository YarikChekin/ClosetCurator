import Foundation
import SwiftData

/// StyleRecommendationService generates recommendations based on user style preferences
class StyleRecommendationService {
    static let shared = StyleRecommendationService()
    
    private init() {}
    
    /// Generates outfit recommendations based on user preferences and conditions
    func generateOutfitRecommendations(
        preferences: StylePreference,
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
        
        // Group items by category
        let categorizedItems = Dictionary(grouping: preferredItems) { $0.category }
        
        // Generate outfit recommendations
        var recommendations: [StyleRecommendation] = []
        
        // First, check if there are existing outfits that match the criteria
        for outfit in allOutfits {
            // Skip invalid outfits
            guard outfit.isValid else { continue }
            
            // Check if outfit matches occasion
            if let requiredOccasion = occasion {
                // This would normally check outfit occasion tags
                // For now, just randomly include some outfits
                if Bool.random() == false {
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
                    forSeason: determineSeason()
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
                forSeason: determineSeason()
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
                forSeason: determineSeason()
            ))
        }
        
        // Generate specific item recommendations
        for category in ClothingCategory.allCases {
            // Only recommend some categories
            if Bool.random() == false {
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
                forSeason: determineSeason()
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
        limit: Int
    ) throws -> [StyleRecommendation] {
        var recommendations: [StyleRecommendation] = []
        
        // Ensure we have tops and bottoms (or dresses)
        guard let tops = categorizedItems[.tops],
              let bottoms = categorizedItems[.bottoms] else {
            return recommendations
        }
        
        // Generate some random combinations
        for _ in 0..<limit {
            guard let top = tops.randomElement(),
                  let bottom = bottoms.randomElement() else {
                continue
            }
            
            let confidence = Double.random(in: 0.6...0.9)
            let adventureLevel = Double.random(in: 0.2...0.8)
            
            recommendations.append(StyleRecommendation(
                id: UUID(),
                type: .outfit,
                targetId: nil,
                confidence: confidence,
                adventureLevel: adventureLevel,
                reason: "This combination of \(top.name) and \(bottom.name) would work well together",
                basedOn: [top.id, bottom.id],
                category: nil,
                style: nil,
                color: nil,
                brand: nil,
                forOccasion: occasion,
                forSeason: determineSeason()
            ))
        }
        
        return recommendations
    }
    
    private func generateBrandRecommendations(basedOn: [String], styles: [StyleTag]) -> [String] {
        // In a real implementation, this would use a database of brands and their style associations
        // For now, return some random brands
        return ["Nike", "Adidas", "Zara", "H&M", "Uniqlo"]
    }
    
    private func generateStyleRecommendations(basedOn: [StyleTag]) -> [StyleTag] {
        // In a real implementation, this would use style compatibility rules
        // For now, return some random styles
        return Array(Set(StyleTag.allCases).subtracting(Set(basedOn)))
    }
    
    private func determineSeason() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2:
            return .winter
        case 3, 4, 5:
            return .spring
        case 6, 7, 8:
            return .summer
        case 9, 10, 11:
            return .fall
        default:
            return .summer
        }
    }
} 