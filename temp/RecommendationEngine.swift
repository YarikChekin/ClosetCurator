import Foundation

class RecommendationEngine {
    func recommendOutfits(from outfits: [Outfit], for weatherTags: [WeatherTag], limit: Int = 5) -> [Outfit] {
        // Filter outfits that match the current weather conditions
        let matchingOutfits = outfits.filter { outfit in
            guard let outfitTags = outfit.weatherTags else { return false }
            return !Set(outfitTags).isDisjoint(with: Set(weatherTags.map { $0.rawValue }))
        }
        
        // Sort outfits by relevance and last worn date
        let sortedOutfits = matchingOutfits.sorted { outfit1, outfit2 in
            // Calculate relevance score based on matching weather tags
            let score1 = calculateRelevanceScore(outfit: outfit1, weatherTags: weatherTags)
            let score2 = calculateRelevanceScore(outfit: outfit2, weatherTags: weatherTags)
            
            if score1 != score2 {
                return score1 > score2
            }
            
            // If scores are equal, prefer outfits that haven't been worn recently
            let date1 = outfit1.lastWorn ?? .distantPast
            let date2 = outfit2.lastWorn ?? .distantPast
            return date1 < date2
        }
        
        // Return the top N recommendations
        return Array(sortedOutfits.prefix(limit))
    }
    
    private func calculateRelevanceScore(outfit: Outfit, weatherTags: [WeatherTag]) -> Int {
        guard let outfitTags = outfit.weatherTags else { return 0 }
        
        let weatherTagStrings = Set(weatherTags.map { $0.rawValue })
        let outfitTagSet = Set(outfitTags)
        
        // Calculate the intersection of weather tags
        let matchingTags = outfitTagSet.intersection(weatherTagStrings)
        
        // Basic scoring: more matching tags = higher score
        return matchingTags.count
    }
    
    func recommendOutfitsForWeek(from outfits: [Outfit], weeklyForecast: [WeatherTag], limit: Int = 3) -> [(Date, [Outfit])] {
        // Group weather tags by day
        let calendar = Calendar.current
        var recommendations: [(Date, [Outfit])] = []
        
        for (index, tags) in weeklyForecast.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: index, to: Date()) else { continue }
            
            let dailyRecommendations = recommendOutfits(from: outfits, for: [tags], limit: limit)
            recommendations.append((date, dailyRecommendations))
        }
        
        return recommendations
    }
    
    func updateOutfitPreferences(outfit: Outfit, liked: Bool) {
        // TODO: Implement machine learning model to learn from user preferences
        // This could involve:
        // 1. Storing user feedback
        // 2. Updating outfit weights/scores
        // 3. Training a recommendation model
        // 4. Using Core ML for personalized recommendations
    }
} 