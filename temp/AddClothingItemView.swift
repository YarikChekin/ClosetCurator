import SwiftUI
import PhotosUI

struct AddClothingItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ClosetViewModel
    
    @State private var name = ""
    @State private var selectedCategory: ClothingCategory = .tops
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ClothingCategory.allCases) { category in
                            Text(category.rawValue.capitalized)
                                .tag(category)
                        }
                    }
                }
                
                Section {
                    PhotosPicker(selection: $selectedItem,
                               matching: .images) {
                        if let selectedImage {
                            selectedImage
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } else {
                            ContentUnavailableView("No Image Selected",
                                                 systemImage: "photo",
                                                 description: Text("Tap to select a photo"))
                        }
                    }
                }
                
                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(name.isEmpty || imageData == nil || isLoading)
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    isLoading = true
                    error = nil
                    
                    do {
                        if let data = try await newValue?.loadTransferable(type: Data.self) {
                            imageData = data
                            if let uiImage = UIImage(data: data) {
                                selectedImage = Image(uiImage: uiImage)
                            }
                        }
                    } catch {
                        self.error = "Failed to load image: \(error.localizedDescription)"
                    }
                    
                    isLoading = false
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func addItem() {
        guard let imageData else { return }
        
        Task {
            do {
                try await viewModel.addClothingItem(name: name,
                                                  category: selectedCategory,
                                                  imageData: imageData)
                dismiss()
            } catch {
                self.error = "Failed to add item: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AddClothingItemView(viewModel: ClosetViewModel(context: PersistenceController.preview.container.viewContext))
} 