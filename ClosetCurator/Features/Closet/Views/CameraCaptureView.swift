import SwiftUI
import AVFoundation
import Vision
import PhotosUI

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CameraCaptureViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .overlay(alignment: .bottom) {
                            HStack {
                                Button("Retake") {
                                    viewModel.capturedImage = nil
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Save") {
                                    Task {
                                        await viewModel.saveItem()
                                        dismiss()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
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
    
    func saveItem() async {
        guard let image = capturedImage else { return }
        
        do {
            if let item = try await clothingDetectionService.detectClothing(in: image) {
                // Save to SwiftData
                // TODO: Implement SwiftData saving
            }
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