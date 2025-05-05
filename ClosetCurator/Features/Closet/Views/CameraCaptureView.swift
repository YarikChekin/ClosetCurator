import SwiftUI
import AVFoundation
import Vision
import PhotosUI
import SwiftData

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CameraCaptureViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var itemName = ""
    @State private var itemCategory: ClothingCategory = .tops
    @State private var itemColor = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                    
                    VStack(spacing: 16) {
                        TextField("Item Name", text: $itemName)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Category", selection: $itemCategory) {
                            ForEach(ClothingCategory.allCases, id: \.self) { category in
                                Text(category.rawValue.capitalized)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        TextField("Color", text: $itemColor)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    
                    HStack {
                        Button("Retake") {
                            viewModel.capturedImage = nil
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Save") {
                            Task {
                                await viewModel.saveItem(
                                    name: itemName,
                                    category: itemCategory,
                                    color: itemColor,
                                    modelContext: modelContext
                                )
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(itemName.isEmpty || itemColor.isEmpty)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Label("Choose from Library", systemImage: "photo.fill")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Clothing Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $viewModel.capturedImage)
            }
            .sheet(isPresented: $showImagePicker) {
                PhotosPicker(selection: $viewModel.selectedItem,
                           matching: .images) {
                    Text("Select Photo")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

class CameraCaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var selectedItem: PhotosPickerItem?
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let clothingDetectionService = ClothingDetectionService()
    private let imageService = ImageService.shared
    
    func saveItem(name: String, category: ClothingCategory, color: String, modelContext: ModelContext) async {
        guard let image = capturedImage else { return }
        
        do {
            // Save the image to disk
            let imageData = image.jpegData(compressionQuality: 0.8)!
            
            // Create new clothing item
            let newItem = ClothingItem(
                name: name,
                category: category,
                color: color,
                dateAdded: Date()
            )
            
            // Save the image and update the item's imageURL
            newItem.imageURL = try await imageService.saveImage(imageData, for: newItem)
            
            // Try to detect properties using ML if available
            if let detectedItem = try? await clothingDetectionService.detectClothing(in: image) {
                // Use detected properties if available
                newItem.subcategory = detectedItem.subcategory
                newItem.mlConfidence = detectedItem.mlConfidence
            }
            
            // Insert into SwiftData
            modelContext.insert(newItem)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 