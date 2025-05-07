import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ClosetView()
                .tabItem {
                    Label("Closet", systemImage: "tshirt")
                }
                .tag(0)
            
            OutfitsView()
                .tabItem {
                    Label("Outfits", systemImage: "person.crop.square")
                }
                .tag(1)
            
            RecommendationsView()
                .tabItem {
                    Label("Recommendations", systemImage: "star")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

struct ClosetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    @State private var showingAddItem = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ClosetViewModel(context: context))
    }
    
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
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ClosetViewModel(context: context))
    }
    
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
        VStack(alignment: .leading, spacing: 8) {
            Text(outfit.name)
                .font(.headline)
            
            Text(outfit.formattedDateCreated)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(outfit.items)) { item in
                        if let imageData = item.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecommendationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ClosetViewModel(context: context))
    }
    
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