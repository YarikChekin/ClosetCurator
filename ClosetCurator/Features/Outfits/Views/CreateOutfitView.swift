import SwiftUI
import SwiftData

struct CreateOutfitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [ClothingItem]
    
    @State private var name = ""
    @State private var selectedItems: Set<ClothingItem> = []
    @State private var notes = ""
    @State private var showingItemPicker = false
    @State private var selectedCategory: ClothingCategory?
    
    private var categorizedItems: [ClothingCategory: [ClothingItem]] {
        Dictionary(grouping: items) { $0.category }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Outfit Details") {
                    TextField("Name", text: $name)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Items") {
                    ForEach(ClothingCategory.allCases, id: \.self) { category in
                        if let items = categorizedItems[category] {
                            DisclosureGroup(category.rawValue.capitalized) {
                                ForEach(items) { item in
                                    HStack {
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
                                        
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .font(.subheadline)
                                            if let brand = item.brand {
                                                Text(brand)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedItems.contains(item) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        toggleItem(item)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveOutfit()
                    }
                    .disabled(name.isEmpty || selectedItems.isEmpty)
                }
            }
        }
    }
    
    private func toggleItem(_ item: ClothingItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            // Check if we already have an item of this category
            if let existingItem = selectedItems.first(where: { $0.category == item.category }) {
                selectedItems.remove(existingItem)
            }
            selectedItems.insert(item)
        }
    }
    
    private func saveOutfit() {
        let outfit = Outfit(
            name: name,
            items: Array(selectedItems),
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(outfit)
        dismiss()
    }
}

#Preview {
    CreateOutfitView()
        .modelContainer(for: [Outfit.self, ClothingItem.self])
} 