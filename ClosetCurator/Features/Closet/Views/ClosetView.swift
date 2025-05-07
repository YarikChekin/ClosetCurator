import SwiftUI
import SwiftData
import DesignTokens

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
        }
    }
    
    private func deleteItems(_ items: [ClothingItem], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

struct ClothingItemRow: View {
    let item: ClothingItem
    
    var body: some View {
        HStack(spacing: DesignTokens.spacing16) {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: DesignTokens.minTappable, height: DesignTokens.minTappable)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
            } else {
                RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: DesignTokens.minTappable, height: DesignTokens.minTappable)
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                Text(item.name)
                    .font(.headline)
                if let brand = item.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.secondaryColor)
                }
            }
        }
        .padding(.vertical, DesignTokens.spacing8)
        .contentShape(Rectangle())
        .frame(minHeight: DesignTokens.minTappable)
    }
}

#Preview {
    ClosetView()
        .modelContainer(for: [ClothingItem.self])
} 