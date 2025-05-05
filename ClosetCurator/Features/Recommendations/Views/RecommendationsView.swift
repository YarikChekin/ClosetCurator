import SwiftUI
import SwiftData
import WeatherKit
import CoreLocation

struct RecommendationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var outfits: [Outfit]
    @Query private var stylePreferences: [StylePreference]
    @StateObject private var weatherService = WeatherService()
    @State private var isLoading = false
    @State private var recommendedOutfits: [Outfit] = []
    @State private var locationManager = CLLocationManager()
    @State private var showingStylePreferenceSetup = false
    
    // Get the user's style preference or nil if none exists
    private var userStylePreference: StylePreference? {
        stylePreferences.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let weather = weatherService.currentWeather {
                    Section {
                        WeatherSummaryView(weather: weather)
                    }
                }
                
                if userStylePreference == nil {
                    Section {
                        Button(action: {
                            showingStylePreferenceSetup = true
                        }) {
                            HStack {
                                Image(systemName: "tshirt.fill")
                                Text("Set up your style preferences")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
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
                                            await provideFeedback(for: outfit, response: .disliked)
                                        }
                                    } label: {
                                        Label("Dislike", systemImage: "hand.thumbsdown")
                                    }
                                    
                                    Button {
                                        Task {
                                            await provideFeedback(for: outfit, response: .liked)
                                        }
                                    } label: {
                                        Label("Like", systemImage: "hand.thumbsup")
                                    }
                                    .tint(.green)
                                    
                                    Button {
                                        Task {
                                            await provideFeedback(for: outfit, response: .tried)
                                        }
                                    } label: {
                                        Label("Tried", systemImage: "checkmark.circle")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
                
                if let preference = userStylePreference {
                    Section("Your Style Profile") {
                        VStack(alignment: .leading) {
                            Text("Adventure Level: \(Int(preference.adventureLevel * 100))%")
                                .font(.subheadline)
                            
                            if !preference.favoriteStyles.isEmpty {
                                Text("Preferred Styles: \(preference.favoriteStyles.map { $0.rawValue.capitalized }.joined(separator: ", "))")
                                    .font(.caption)
                            }
                            
                            if !preference.favoriteColors.isEmpty {
                                Text("Favorite Colors: \(preference.favoriteColors.prefix(3).joined(separator: ", "))")
                                    .font(.caption)
                            }
                            
                            NavigationLink(destination: StyleBoardView()) {
                                Text("View Style Boards")
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingStylePreferenceSetup = true
                    }) {
                        Image(systemName: "tshirt")
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
                
                // Create a default style preference if none exists
                if userStylePreference == nil {
                    let newPreference = StylePreference(
                        favoriteStyles: [.casual, .modern],
                        favoriteColors: ["Blue", "Black", "Gray"],
                        adventureLevel: 0.5
                    )
                    modelContext.insert(newPreference)
                    try? modelContext.save()
                }
            }
            .sheet(isPresented: $showingStylePreferenceSetup) {
                StylePreferenceSetupView(stylePreference: userStylePreference)
                    .environment(\.modelContext, modelContext)
                    .onDisappear {
                        Task {
                            await generateRecommendations()
                        }
                    }
            }
        }
    }
    
    private func loadWeather() async {
        isLoading = true
        defer { isLoading = false }
        
        await weatherService.getCurrentWeather()
    }
    
    private func generateRecommendations() async {
        guard let weather = weatherService.currentWeather else { return }
        
        // Convert weather to weather tags
        let weatherTags = [
            weather.temperature.map { temp in
                if temp >= 25 { return WeatherTag.hot }
                else if temp >= 18 { return WeatherTag.warm }
                else if temp >= 10 { return WeatherTag.cool }
                else { return WeatherTag.cold }
            },
            weather.condition.map { condition in
                if condition.lowercased().contains("rain") { return WeatherTag.rainy }
                else if condition.lowercased().contains("snow") { return WeatherTag.snowy }
                else { return nil }
            }
        ].compactMap { $0 }.compactMap { $0 }
        
        do {
            recommendedOutfits = try await RecommendationService.shared.generateRecommendations(
                outfits: outfits,
                weatherTags: weatherTags,
                stylePreference: userStylePreference,
                limit: 5,
                modelContext: modelContext
            )
        } catch {
            print("Error generating recommendations: \(error)")
        }
    }
    
    private func provideFeedback(for outfit: Outfit, response: StyleFeedback.FeedbackResponse) async {
        guard let weather = weatherService.currentWeather, let preference = userStylePreference else { return }
        
        // Add feedback to the system
        let feedback = StyleFeedback(
            recommendationType: .outfit,
            recommendationId: outfit.id,
            response: response,
            rating: response == .liked ? 5 : (response == .disliked ? 1 : 3),
            context: StyleFeedback.FeedbackContext(
                occasion: nil,
                weather: weather,
                location: nil,
                time: Date(),
                adventureLevel: nil
            ),
            preference: preference
        )
        
        // Save the feedback
        modelContext.insert(feedback)
        try? modelContext.save()
        
        // Process the feedback to update preferences
        do {
            try await RecommendationService.shared.processStyleFeedback(
                feedback: feedback,
                stylePreference: preference,
                modelContext: modelContext
            )
            
            await generateRecommendations()
        } catch {
            print("Error processing feedback: \(error)")
        }
    }
}

// A placeholder view for style preference setup
struct StylePreferenceSetupView: View {
    var stylePreference: StylePreference?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStyles: [StyleTag] = []
    @State private var selectedColors: [String] = []
    @State private var adventureLevel: Double = 0.5
    
    private let availableColors = [
        "Black", "White", "Gray", "Navy", "Blue", 
        "Green", "Red", "Yellow", "Purple", "Pink", 
        "Brown", "Beige", "Orange", "Teal"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Style Preferences") {
                    Text("Select your preferred styles:")
                    
                    ForEach(StyleTag.allCases, id: \.self) { style in
                        Button(action: {
                            toggleStyle(style)
                        }) {
                            HStack {
                                Text(style.rawValue.capitalized)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedStyles.contains(style) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Color Preferences") {
                    Text("Select your favorite colors:")
                    
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            toggleColor(color)
                        }) {
                            HStack {
                                Text(color)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedColors.contains(color) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Adventure Level") {
                    Text("How adventurous do you want your recommendations to be?")
                        .font(.caption)
                    
                    VStack {
                        Slider(value: $adventureLevel, in: 0...1, step: 0.05)
                        
                        HStack {
                            Text("Conservative")
                                .font(.caption)
                            Spacer()
                            Text("Adventurous")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Style Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreferences()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load existing preferences if they exist
                if let preference = stylePreference {
                    selectedStyles = preference.favoriteStyles
                    selectedColors = preference.favoriteColors
                    adventureLevel = preference.adventureLevel
                }
            }
        }
    }
    
    private func toggleStyle(_ style: StyleTag) {
        if selectedStyles.contains(style) {
            selectedStyles.removeAll { $0 == style }
        } else {
            selectedStyles.append(style)
        }
    }
    
    private func toggleColor(_ color: String) {
        if selectedColors.contains(color) {
            selectedColors.removeAll { $0 == color }
        } else {
            selectedColors.append(color)
        }
    }
    
    private func savePreferences() {
        if let preference = stylePreference {
            // Update existing preference
            preference.updatePreferences(
                newColors: selectedColors,
                newStyles: selectedStyles
            )
            preference.updateAdventureLevel(newLevel: adventureLevel)
        } else {
            // Create new preference
            let newPreference = StylePreference(
                favoriteColors: selectedColors,
                favoriteStyles: selectedStyles,
                adventureLevel: adventureLevel
            )
            modelContext.insert(newPreference)
        }
        
        try? modelContext.save()
    }
}

struct WeatherSummaryView: View {
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: getWeatherIcon(for: weather.condition ?? ""))
                    .font(.title)
                Text("\(Int(weather.temperature ?? 0))°")
                    .font(.title)
            }
            
            Text(weather.condition ?? "Unknown")
                .font(.subheadline)
            
            Text("Location: \(weather.location ?? "Current Location")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func getWeatherIcon(for condition: String) -> String {
        let condition = condition.lowercased()
        
        if condition.contains("rain") || condition.contains("drizzle") {
            return "cloud.rain"
        } else if condition.contains("snow") {
            return "cloud.snow"
        } else if condition.contains("cloud") {
            return "cloud"
        } else if condition.contains("clear") || condition.contains("sun") {
            return "sun.max"
        } else if condition.contains("partly") {
            return "cloud.sun"
        } else {
            return "thermometer"
        }
    }
}

#Preview {
    RecommendationsView()
        .modelContainer(for: [Outfit.self, ClothingItem.self, StylePreference.self, StyleFeedback.self])
} 