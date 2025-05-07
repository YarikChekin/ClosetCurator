import SwiftUI
import SwiftData

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
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            Text(outfit.name)
                .font(.headline)
            
            HStack(spacing: DesignTokens.spacing8) {
                ForEach(outfit.items.prefix(3)) { item in
                    if let imageURL = item.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: DesignTokens.spacing32, height: DesignTokens.spacing32)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
                    }
                }
                
                if outfit.items.count > 3 {
                    Text("+\(outfit.items.count - 3)")
                        .font(.caption)
                        .foregroundColor(DesignTokens.secondaryColor)
                }
            }
            
            if let lastWorn = outfit.lastWorn {
                Text("Last worn: \(lastWorn.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(DesignTokens.secondaryColor)
            }
        }
        .padding(.vertical, DesignTokens.spacing8)
        .contentShape(Rectangle())
        .frame(minHeight: DesignTokens.minTappable)
    }
}

#Preview {
    OutfitsView()
        .modelContainer(for: [Outfit.self, ClothingItem.self])
} 