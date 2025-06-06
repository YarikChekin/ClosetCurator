import Foundation
import CoreML
import SwiftData

actor RecommendationService {
    static let shared = RecommendationService()
    
    private let model: MLModel
    private let modelURL: URL
    private let styleRecommendationService = StyleRecommendationService.shared
    
    private init() {
        // TODO: Replace with actual model URL when we have a trained model
        modelURL = Bundle.main.url(forResource: "OutfitRecommender", withExtension: "mlmodelc")!
        model = try! MLModel(contentsOf: modelURL)
    }
    
    /// Enhanced recommendation method that integrates style preferences
    func generateRecommendations(
        outfits: [Outfit],
        stylePreference: StylePreference?,
        limit: Int = 5,
        modelContext: ModelContext
    ) async throws -> [Outfit] {
        // If we have style preferences, use the enhanced algorithm
        if let stylePreference = stylePreference {
            return try await generateEnhancedRecommendations(
                outfits: outfits,
                stylePreference: stylePreference,
                limit: limit,
                modelContext: modelContext
            )
        }
        
        // Fall back to basic algorithm if no style preferences are available
        let userPreferences = stylePreference?.favoriteStyles ?? []
        return try await generateBasicRecommendations(
            outfits: outfits,
            userPreferences: userPreferences,
            limit: limit
        )
    }
    
    /// Basic recommendation algorithm (legacy)
    private func generateBasicRecommendations(
        outfits: [Outfit],
        userPreferences: [StyleTag],
        limit: Int = 5
    ) async throws -> [Outfit] {
        // For now, we'll implement a rule-based recommendation system
        // This will be replaced with ML-based recommendations once we have a trained model
        
        var scoredOutfits = outfits.map { outfit -> (outfit: Outfit, score: Double) in
            var score = 0.0
            
            // Style preference score
            let styleMatchCount = Set(outfit.styleTags).intersection(Set(userPreferences)).count
            score += Double(styleMatchCount) * 1.5
            
            // Recency score (prefer less recently worn items)
            if let lastWorn = outfit.lastWorn {
                let daysSinceLastWorn = Calendar.current.dateComponents([.day], from: lastWorn, to: Date()).day ?? 0
                score += min(Double(daysSinceLastWorn) * 0.1, 1.0)
            }
            
            // Wear count score (prefer less worn items)
            score += max(0, 1.0 - (Double(outfit.wearCount) * 0.1))
            
            // Favorite bonus
            if outfit.favorite {
                score += 1.0
            }
            
            return (outfit, score)
        }
        
        // Sort by score and return top recommendations
        scoredOutfits.sort { $0.score > $1.score }
        return scoredOutfits.prefix(limit).map { $0.outfit }
    }
    
    /// Enhanced recommendation algorithm that integrates with the style system
    private func generateEnhancedRecommendations(
        outfits: [Outfit],
        stylePreference: StylePreference,
        limit: Int = 5,
        modelContext: ModelContext
    ) async throws -> [Outfit] {
        // Get style recommendations
        let styleRecommendations = try await styleRecommendationService.generateOutfitRecommendations(
            preferences: stylePreference,
            occasion: nil,
            modelContext: modelContext
        )
        
        // Process existing outfits
        var recommendedOutfits: [Outfit] = []
        
        // First, add outfits that were recommended by the style system
        for recommendation in styleRecommendations where recommendation.type == .outfit {
            if let targetId = recommendation.targetId,
               let outfit = outfits.first(where: { $0.id == targetId }) {
                recommendedOutfits.append(outfit)
            } else if let outfitItemIds = recommendation.basedOn {
                // This is a new outfit combination
                // In a real implementation, we would create a new outfit from these items
                // For now, let's find if these item IDs match an existing outfit closely
                let matchingOutfit = findMatchingOutfit(outfits: outfits, itemIds: outfitItemIds)
                if let matchingOutfit = matchingOutfit, !recommendedOutfits.contains(where: { $0.id == matchingOutfit.id }) {
                    recommendedOutfits.append(matchingOutfit)
                }
            }
        }
        
        // If we don't have enough outfits, apply the basic algorithm but with enhanced scoring
        if recommendedOutfits.count < limit {
            let scoredOutfits = scoreOutfitsWithStylePreference(
                outfits: outfits.filter { !recommendedOutfits.contains($0) },
                stylePreference: stylePreference
            )
            
            let additionalOutfits = scoredOutfits
                .prefix(limit - recommendedOutfits.count)
                .map { $0.outfit }
            
            recommendedOutfits.append(contentsOf: additionalOutfits)
        }
        
        return recommendedOutfits
    }
    
    /// Score outfits using style preference data
    private func scoreOutfitsWithStylePreference(
        outfits: [Outfit],
        stylePreference: StylePreference
    ) -> [(outfit: Outfit, score: Double)] {
        let scoredOutfits = outfits.map { outfit -> (outfit: Outfit, score: Double) in
            var score = 0.0
            
            // Style tag preference score
            let styleMatchCount = Set(outfit.styleTags).intersection(Set(stylePreference.favoriteStyles)).count
            score += Double(styleMatchCount) * 1.5
            
            // Color preference score
            let outfitColors = outfit.items.map { $0.color }
            let colorMatchCount = Set(outfitColors).intersection(Set(stylePreference.favoriteColors)).count
            score += Double(colorMatchCount) * 1.0
            
            // Brand preference score
            let outfitBrands = outfit.items.compactMap { $0.brand }
            let brandMatchCount = Set(outfitBrands).intersection(Set(stylePreference.favoredBrands)).count
            score += Double(brandMatchCount) * 0.8
            
            // Recency score (prefer less recently worn items)
            if let lastWorn = outfit.lastWorn {
                let daysSinceLastWorn = Calendar.current.dateComponents([.day], from: lastWorn, to: Date()).day ?? 0
                score += min(Double(daysSinceLastWorn) * 0.1, 1.0)
            }
            
            // Wear count score (prefer less worn items)
            score += max(0, 1.0 - (Double(outfit.wearCount) * 0.1))
            
            // Favorite bonus
            if outfit.favorite {
                score += 1.0
            }
            
            return (outfit, score)
        }
        
        return scoredOutfits.sorted { $0.score > $1.score }
    }
    
    /// Find an outfit that contains most of the specified items
    private func findMatchingOutfit(outfits: [Outfit], itemIds: [UUID]) -> Outfit? {
        var bestMatch: (outfit: Outfit, matchCount: Int)? = nil
        
        for outfit in outfits {
            let outfitItemIds = outfit.items.map { $0.id }
            let matchCount = Set(outfitItemIds).intersection(Set(itemIds)).count
            
            if matchCount > 0 && (bestMatch == nil || matchCount > bestMatch!.matchCount) {
                bestMatch = (outfit, matchCount)
            }
        }
        
        return bestMatch?.outfit
    }
    
    func updateModel(with feedback: OutfitFeedback) async throws {
        // TODO: Implement model updating based on user feedback
        // This will be implemented when we have a trained model that supports updating
    }
    
    /// Process style feedback to update style preferences
    func processStyleFeedback(
        feedback: StyleFeedback,
        stylePreference: StylePreference,
        modelContext: ModelContext
    ) async throws {
        // TODO: Implement style feedback processing
    }
}

struct OutfitFeedback {
    let outfit: Outfit
    let rating: Int
    let styleTags: [StyleTag]
    let date: Date
} 