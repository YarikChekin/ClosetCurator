import Foundation
import CoreML
import SwiftData

actor RecommendationService {
    static let shared = RecommendationService()
    
    private let model: MLModel
    private let modelURL: URL
    
    private init() {
        // TODO: Replace with actual model URL when we have a trained model
        modelURL = Bundle.main.url(forResource: "OutfitRecommender", withExtension: "mlmodelc")!
        model = try! MLModel(contentsOf: modelURL)
    }
    
    func generateRecommendations(
        outfits: [Outfit],
        weatherTags: [WeatherTag],
        userPreferences: [StyleTag],
        limit: Int = 5
    ) async throws -> [Outfit] {
        // For now, we'll implement a rule-based recommendation system
        // This will be replaced with ML-based recommendations once we have a trained model
        
        var scoredOutfits = outfits.map { outfit -> (outfit: Outfit, score: Double) in
            var score = 0.0
            
            // Weather compatibility score
            let weatherMatchCount = Set(outfit.weatherTags).intersection(Set(weatherTags)).count
            score += Double(weatherMatchCount) * 2.0
            
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
    
    func updateModel(with feedback: OutfitFeedback) async throws {
        // TODO: Implement model updating based on user feedback
        // This will be implemented when we have a trained model that supports updating
    }
}

struct OutfitFeedback {
    let outfit: Outfit
    let rating: Int
    let weatherTags: [WeatherTag]
    let styleTags: [StyleTag]
    let date: Date
} 