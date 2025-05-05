import SwiftUI
import SwiftData

struct OutfitSuggestionsView: View {
    @EnvironmentObject private var weatherService: WeatherService
    @StateObject private var viewModel = OutfitSuggestionsViewModel()
    @State private var showFeedback = false
    @State private var selectedOutfit: Outfit?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weather Card
                    WeatherCardView()
                        .padding(.horizontal)
                    
                    // Today's Suggestions
                    VStack(alignment: .leading) {
                        Text("Today's Suggestions")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(viewModel.suggestedOutfits) { outfit in
                                    OutfitCardView(outfit: outfit) {
                                        selectedOutfit = outfit
                                        showFeedback = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Outfits
                    VStack(alignment: .leading) {
                        Text("Recent Outfits")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(viewModel.recentOutfits) { outfit in
                            OutfitRowView(outfit: outfit)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Outfit Suggestions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshSuggestions()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showFeedback) {
                if let outfit = selectedOutfit {
                    OutfitFeedbackView(outfit: outfit) { rating in
                        viewModel.updateOutfitRating(outfit, rating: rating)
                    }
                }
            }
            .task {
                await viewModel.loadSuggestions()
            }
        }
    }
}

struct WeatherCardView: View {
    @EnvironmentObject private var weatherService: WeatherService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    if let temp = weatherService.getCurrentTemperature() {
                        Text("\(Int(temp))°")
                            .font(.system(size: 48, weight: .bold))
                    }
                    
                    Text(weatherService.getCurrentConditions().map { $0.rawValue }.joined(separator: ", "))
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Weather icon based on conditions
                Image(systemName: weatherIcon)
                    .font(.system(size: 48))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private var weatherIcon: String {
        let conditions = weatherService.getCurrentConditions()
        if conditions.contains(.rainy) { return "cloud.rain.fill" }
        if conditions.contains(.snowy) { return "cloud.snow.fill" }
        if conditions.contains(.cloudy) { return "cloud.fill" }
        if conditions.contains(.sunny) { return "sun.max.fill" }
        return "cloud.fill"
    }
}

struct OutfitCardView: View {
    let outfit: Outfit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                // Outfit preview image
                if let firstItem = outfit.items.first,
                   let imageURL = firstItem.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 200, height: 250)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name)
                        .font(.headline)
                    
                    Text(outfit.styleTags.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 3)
        }
        .buttonStyle(.plain)
    }
}

struct OutfitFeedbackView: View {
    let outfit: Outfit
    let onFeedback: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("How do you like this outfit?")
                    .font(.title2)
                
                HStack(spacing: 30) {
                    Button {
                        rating = 1
                        onFeedback(1)
                        dismiss()
                    } label: {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(rating == 1 ? .red : .gray)
                    }
                    
                    Button {
                        rating = 2
                        onFeedback(2)
                        dismiss()
                    } label: {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 40))
                            .foregroundColor(rating == 2 ? .green : .gray)
                    }
                }
                
                Text("Your feedback helps improve future suggestions!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Outfit Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class OutfitSuggestionsViewModel: ObservableObject {
    @Published var suggestedOutfits: [Outfit] = []
    @Published var recentOutfits: [Outfit] = []
    
    func loadSuggestions() async {
        // TODO: Implement outfit suggestions based on weather and user preferences
    }
    
    func refreshSuggestions() async {
        // TODO: Implement refresh logic
    }
    
    func updateOutfitRating(_ outfit: Outfit, rating: Int) {
        outfit.updateRating(rating)
        // TODO: Update ML model with feedback
    }
} 