import SwiftUI
import SwiftData
import WeatherKit
import CoreLocation

struct RecommendationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var outfits: [Outfit]
    @StateObject private var weatherService = WeatherService()
    @State private var isLoading = false
    @State private var recommendedOutfits: [Outfit] = []
    @State private var locationManager = CLLocationManager()
    @State private var userPreferences: [StyleTag] = [.casual, .modern] // Default preferences
    
    var body: some View {
        NavigationStack {
            List {
                if let weather = weatherService.currentWeather {
                    Section {
                        WeatherSummaryView(weather: weather)
                    }
                }
                
                Section("Recommended Outfits") {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if recommendedOutfits.isEmpty {
                        Text("No recommendations available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(recommendedOutfits) { outfit in
                            OutfitRow(outfit: outfit)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        Task {
                                            await provideFeedback(for: outfit, rating: 1)
                                        }
                                    } label: {
                                        Label("Dislike", systemImage: "hand.thumbsdown")
                                    }
                                    
                                    Button {
                                        Task {
                                            await provideFeedback(for: outfit, rating: 5)
                                        }
                                    } label: {
                                        Label("Like", systemImage: "hand.thumbsup")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(StyleTag.allCases, id: \.self) { tag in
                            Button {
                                togglePreference(tag)
                            } label: {
                                Label(tag.rawValue.capitalized,
                                      systemImage: userPreferences.contains(tag) ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    } label: {
                        Label("Style Preferences", systemImage: "person.crop.circle")
                    }
                }
            }
            .task {
                await loadWeather()
                await generateRecommendations()
            }
            .refreshable {
                await loadWeather()
                await generateRecommendations()
            }
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    private func loadWeather() async {
        isLoading = true
        defer { isLoading = false }
        
        if let location = locationManager.location {
            await weatherService.fetchWeather(for: location)
        }
    }
    
    private func generateRecommendations() async {
        guard let weather = weatherService.currentWeather else { return }
        
        let weatherTags = weatherService.getWeatherTags(for: weather)
        
        do {
            recommendedOutfits = try await RecommendationService.shared.generateRecommendations(
                outfits: outfits,
                weatherTags: weatherTags,
                userPreferences: userPreferences
            )
        } catch {
            print("Error generating recommendations: \(error)")
        }
    }
    
    private func togglePreference(_ tag: StyleTag) {
        if userPreferences.contains(tag) {
            userPreferences.removeAll { $0 == tag }
        } else {
            userPreferences.append(tag)
        }
        
        Task {
            await generateRecommendations()
        }
    }
    
    private func provideFeedback(for outfit: Outfit, rating: Int) async {
        guard let weather = weatherService.currentWeather else { return }
        
        let feedback = OutfitFeedback(
            outfit: outfit,
            rating: rating,
            weatherTags: weatherService.getWeatherTags(for: weather),
            styleTags: userPreferences,
            date: Date()
        )
        
        do {
            try await RecommendationService.shared.updateModel(with: feedback)
            await generateRecommendations()
        } catch {
            print("Error updating model: \(error)")
        }
    }
}

struct WeatherSummaryView: View {
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: weather.currentWeather.symbolName)
                    .font(.title)
                Text("\(Int(weather.currentWeather.temperature.value))°")
                    .font(.title)
            }
            
            Text(weather.currentWeather.condition.description)
                .font(.subheadline)
            
            if let forecast = weather.dailyForecast.first {
                Text("High: \(Int(forecast.highTemperature.value))° Low: \(Int(forecast.lowTemperature.value))°")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RecommendationsView()
        .modelContainer(for: [Outfit.self, ClothingItem.self])
} 