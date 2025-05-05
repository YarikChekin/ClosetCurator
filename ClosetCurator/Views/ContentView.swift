import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ClosetViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ClosetView(viewModel: viewModel)
                .tabItem {
                    Label("Closet", systemImage: "tshirt")
                }
                .tag(0)
            
            OutfitsView(viewModel: viewModel)
                .tabItem {
                    Label("Outfits", systemImage: "person.crop.rectangle.stack")
                }
                .tag(1)
            
            RecommendationsView(viewModel: viewModel)
                .tabItem {
                    Label("Recommendations", systemImage: "wand.and.stars")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .task {
            await viewModel.updateWeather()
        }
    }
}

struct ClosetView: View {
    @ObservedObject var viewModel: ClosetViewModel
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.clothingItems) { item in
                    ClothingItemRow(item: item)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        viewModel.deleteClothingItem(viewModel.clothingItems[index])
                    }
                }
            }
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddClothingItemView(viewModel: viewModel)
            }
        }
    }
}

struct ClothingItemRow: View {
    let item: ClothingItem
    
    var body: some View {
        HStack {
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text(item.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct OutfitsView: View {
    @ObservedObject var viewModel: ClosetViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.recommendedOutfits) { outfit in
                    OutfitRow(outfit: outfit)
                }
            }
            .navigationTitle("My Outfits")
        }
    }
}

struct OutfitRow: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(outfit.name)
                .font(.headline)
            Text(outfit.formattedDateCreated)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct RecommendationsView: View {
    @ObservedObject var viewModel: ClosetViewModel
    
    var body: some View {
        NavigationView {
            List {
                if let weather = viewModel.currentWeather {
                    WeatherInfoView(weather: weather)
                }
                
                ForEach(viewModel.recommendedOutfits) { outfit in
                    OutfitRow(outfit: outfit)
                }
            }
            .navigationTitle("Recommendations")
            .refreshable {
                await viewModel.updateWeather()
            }
        }
    }
}

struct WeatherInfoView: View {
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Current Weather")
                .font(.headline)
            Text("Temperature: \(weather.temperature)°")
            Text("Conditions: \(weather.condition)")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("App Settings")) {
                    Toggle("Enable Notifications", isOn: .constant(true))
                    Toggle("Sync with iCloud", isOn: .constant(true))
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
} 