import SwiftUI
import SwiftData

struct OutfitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var outfits: [Outfit]
    @State private var showingAddOutfit = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Favorites") {
                    let favoriteOutfits = outfits.filter { $0.isFavorite }
                    ForEach(favoriteOutfits) { outfit in
                        OutfitRow(outfit: outfit)
                    }
                }
                
                Section("Recent") {
                    let recentOutfits = outfits
                        .filter { !$0.isFavorite }
                        .sorted { ($0.lastWorn ?? .distantPast) > ($1.lastWorn ?? .distantPast) }
                    ForEach(recentOutfits) { outfit in
                        OutfitRow(outfit: outfit)
                    }
                }
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
}

struct OutfitRow: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(outfit.name)
                .font(.headline)
            
            HStack {
                ForEach(outfit.items.prefix(3)) { item in
                    if let imageURL = item.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                if outfit.items.count > 3 {
                    Text("+\(outfit.items.count - 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let lastWorn = outfit.lastWorn {
                Text("Last worn: \(lastWorn.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OutfitsView()
        .modelContainer(for: [Outfit.self, ClothingItem.self])
} 