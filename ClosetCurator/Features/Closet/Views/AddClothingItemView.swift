import SwiftUI
import SwiftData
import PhotosUI

struct AddClothingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var category: ClothingCategory = .tops
    @State private var subcategory = ""
    @State private var color = ""
    @State private var brand = ""
    @State private var size = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private let subcategories: [ClothingCategory: [String]] = [
        .tops: ["T-Shirt", "Blouse", "Sweater", "Tank Top", "Button-Up"],
        .bottoms: ["Jeans", "Pants", "Shorts", "Skirt"],
        .dresses: ["Casual", "Formal", "Maxi", "Mini"],
        .outerwear: ["Jacket", "Coat", "Blazer", "Cardigan"],
        .shoes: ["Sneakers", "Boots", "Sandals", "Heels", "Flats"],
        .accessories: ["Hat", "Scarf", "Jewelry", "Bag", "Belt"]
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    if let selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    PhotosPicker(selection: $selectedPhoto,
                               matching: .images,
                               photoLibrary: .shared()) {
                        Label(selectedImage == nil ? "Add Photo" : "Change Photo",
                              systemImage: "photo")
                    }
                }
                
                Section("Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized)
                                .tag(category)
                        }
                    }
                    
                    if let subcategories = subcategories[category] {
                        Picker("Type", selection: $subcategory) {
                            Text("Select Type").tag("")
                            ForEach(subcategories, id: \.self) { subcategory in
                                Text(subcategory).tag(subcategory)
                            }
                        }
                    }
                    
                    TextField("Color", text: $color)
                    TextField("Brand", text: $brand)
                    TextField("Size", text: $size)
                }
                
                Section("Additional Info") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Clothing Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveItem()
                        }
                    }
                    .disabled(name.isEmpty || isProcessing)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        if let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
        }
    }
    
    private func saveItem() async {
        isProcessing = true
        errorMessage = nil
        
        do {
            let item = ClothingItem(
                name: name,
                category: category,
                subcategory: subcategory.isEmpty ? nil : subcategory,
                color: color,
                brand: brand.isEmpty ? nil : brand,
                size: size.isEmpty ? nil : size,
                notes: notes.isEmpty ? nil : notes
            )
            
            if let imageData = selectedImageData {
                let processedData = try await ImageService.shared.processImage(imageData)
                let imageURL = try await ImageService.shared.saveImage(processedData, for: item)
                item.imageURL = imageURL
            }
            
            modelContext.insert(item)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
}

#Preview {
    AddClothingItemView()
        .modelContainer(for: [ClothingItem.self])
} 