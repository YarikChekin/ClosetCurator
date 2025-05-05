import SwiftUI
import SwiftData

@main
struct ClosetCuratorApp: App {
    @StateObject private var weatherService = WeatherService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ClothingItem.self, Outfit.self])
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            ClosetView()
                .tabItem {
                    Label("Closet", systemImage: "tshirt")
                }
            
            OutfitsView()
                .tabItem {
                    Label("Outfits", systemImage: "person.crop.rectangle.stack")
                }
            
            RecommendationsView()
                .tabItem {
                    Label("Recommendations", systemImage: "wand.and.stars")
                }
        }
    }
}

#Preview {
    ContentView()
} 