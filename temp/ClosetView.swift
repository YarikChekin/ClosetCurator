import SwiftUI

struct ClosetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    @State private var showingAddItem = false
    @State private var selectedCategory: ClothingCategory = .all
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ClosetViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ClothingCategory.allCases) { category in
                        Text(category.rawValue.capitalized)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    ForEach(viewModel.clothingItems.filter { selectedCategory == .all || $0.category == selectedCategory }) { item in
                        ClothingItemRow(item: item)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteClothingItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
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
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(item.name ?? "Unnamed Item")
                    .font(.headline)
                Text(item.category?.rawValue.capitalized ?? "Unknown Category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ForEach(item.weatherTags ?? [], id: \.self) { tag in
                Image(systemName: tag.systemImage)
                    .foregroundColor(tag.color)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ClosetView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 