import SwiftUI
import SwiftData

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
        HStack {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                if let brand = item.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ClosetView()
        .modelContainer(for: [ClothingItem.self])
} 