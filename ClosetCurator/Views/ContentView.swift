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

struct ClosetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClothingItem]
    @State private var showingAddItem = false
    @State private var selectedCategory: ClothingCategory?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    Section(category.rawValue.capitalized) {
                        let categoryItems = items.filter { $0.category == category }
                        ForEach(categoryItems) { item in
                            ClothingItemRow(item: item)
                        }
                        .onDelete { indexSet in
                            deleteItems(categoryItems, at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddClothingItemView()
            }
            .onAppear {
                DebugLogger.info("ClosetView appeared with \(items.count) items")
                for category in ClothingCategory.allCases {
                    let count = items.filter { $0.category == category }.count
                    DebugLogger.info("  - \(category.rawValue): \(count) items")
                }
            }
        }
    }
    
    private func deleteItems(_ items: [ClothingItem], at offsets: IndexSet) {
        for index in offsets {
            DebugLogger.info("Deleting item: \(items[index].name)")
            modelContext.delete(items[index])
        }
    }
}

struct ClothingItemRow: View {
    let item: ClothingItem
    
    var body: some View {
        HStack {
            if let imageURL = item.imageURL,
               let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text(item.category.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct OutfitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var outfits: [Outfit]
    @State private var showingAddOutfit = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(outfits) { outfit in
                    OutfitRow(outfit: outfit)
                }
                .onDelete(perform: deleteOutfits)
            }
            .navigationTitle("My Outfits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddOutfit = true }) {
                        Label("Create Outfit", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddOutfit) {
                CreateOutfitView()
            }
        }
    }
    
    private func deleteOutfits(at offsets: IndexSet) {
        let outfitsToDelete = offsets.map { outfits[$0] }
        for outfit in outfitsToDelete {
            modelContext.delete(outfit)
        }
    }
}

struct OutfitRow: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(outfit.name)
                .font(.headline)
            
            Text(formattedDate(outfit.dateCreated))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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