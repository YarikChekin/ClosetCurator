import SwiftUI
import SwiftData
import PhotosUI

struct AddClothingItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var category: ClothingCategory = .tops
    @State private var color = ""
    @State private var brand = ""
    @State private var size = ""
    @State private var notes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized)
                                .tag(category)
                        }
                    }
                    
                    TextField("Color", text: $color)
                    TextField("Brand", text: $brand)
                    TextField("Size", text: $size)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section("Photo") {
                    HStack {
                        Spacer()
                        
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            Image(systemName: "camera")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .frame(height: 200)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Button("Camera") {
                            showingCamera = true
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Photo Library") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.isEmpty || color.isEmpty)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func saveItem() {
        Task {
            // Create the new item
            let newItem = ClothingItem(
                name: name,
                category: category,
                color: color,
                brand: brand.isEmpty ? nil : brand,
                size: size.isEmpty ? nil : size,
                notes: notes.isEmpty ? nil : notes
            )
            
            // Save the image if one was selected
            if let image = selectedImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                do {
                    let imageService = ImageService.shared
                    newItem.imageURL = try await imageService.saveImage(imageData, for: newItem)
                } catch {
                    print("Error saving image: \(error)")
                }
            }
            
            // Save to SwiftData
            modelContext.insert(newItem)
            dismiss()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

#Preview {
    AddClothingItemView()
        .modelContainer(for: [ClothingItem.self])
} 