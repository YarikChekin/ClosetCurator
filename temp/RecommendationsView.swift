import SwiftUI
import WeatherKit

struct RecommendationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ClosetViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if let error = viewModel.error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            Task {
                                await viewModel.updateWeather()
                            }
                        }
                    }
                } else {
                    WeatherSummaryView(weather: viewModel.currentWeather)
                        .padding()
                    
                    List {
                        ForEach(viewModel.recommendedOutfits) { outfit in
                            OutfitRecommendationRow(outfit: outfit)
                                .swipeActions {
                                    Button {
                                        viewModel.markAsWorn(outfit)
                                    } label: {
                                        Label("Wear", systemImage: "checkmark")
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
                    Button {
                        Task {
                            await viewModel.updateWeather()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await viewModel.updateWeather()
        }
    }
}

struct WeatherSummaryView: View {
    let weather: CurrentWeather?
    
    var body: some View {
        if let weather = weather {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: weather.symbolName)
                        .font(.title)
                    Text(weather.condition.description)
                        .font(.title2)
                }
                
                Text("\(Int(weather.temperature.value))°\(weather.temperature.unit.symbol)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    Label("\(Int(weather.humidity * 100))%", systemImage: "humidity")
                    Text("•")
                    Label("\(weather.windSpeed.formatted()) \(weather.windSpeed.unit.symbol)", systemImage: "wind")
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 5)
        }
    }
}

struct OutfitRecommendationRow: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(outfit.name ?? "Unnamed Outfit")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(outfit.items?.allObjects as? [ClothingItem] ?? [], id: \.id) { item in
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            HStack {
                ForEach(outfit.weatherTags ?? [], id: \.self) { tag in
                    Image(systemName: tag.systemImage)
                        .foregroundColor(tag.color)
                }
                
                Spacer()
                
                if let lastWorn = outfit.lastWorn {
                    Text("Last worn: \(lastWorn.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecommendationsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 