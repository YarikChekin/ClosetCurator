import SwiftUI
import SwiftData

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
                    Label("Outfits", systemImage: "person.crop.rectangle.stack")
                }
                .tag(1)
            
            StyleBoardView()
                .tabItem {
                    Label("Style Boards", systemImage: "square.grid.2x2")
                }
                .tag(2)
            
            RecommendationsView()
                .tabItem {
                    Label("Recommendations", systemImage: "wand.and.stars")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            DebugLogger.info("Tab changed from \(oldValue) to \(newValue)")
        }
        .onAppear {
            DebugLogger.info("ContentView appeared")
        }
    }
}

struct RecommendationsView: View {
    @Query private var outfits: [Outfit]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(recommendedOutfits) { outfit in
                    OutfitRow(outfit: outfit)
                }
            }
            .navigationTitle("Recommendations")
        }
    }
    
    private var recommendedOutfits: [Outfit] {
        // Simple logic for now - just show all outfits
        // We'll implement smarter recommendations later
        return outfits
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