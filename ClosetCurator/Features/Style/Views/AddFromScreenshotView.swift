import SwiftUI
import PhotosUI

struct AddFromScreenshotView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var board: StyleBoard
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var screenShots: [UIImage] = []
    @State private var selectedImages: Set<UUID> = []
    @State private var isProcessing = false
    @State private var processingMessage = "Processing screenshots..."
    
    var body: some View {
        NavigationStack {
            VStack {
                // Screenshot selection
                if screenShots.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No screenshots selected")
                            .font(.headline)
                        
                        Text("Choose screenshots from your photo library that contain fashion inspiration.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Choose Screenshots", systemImage: "photo.on.rectangle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.vertical, 60)
                } else {
                    // Display selected screenshots
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                            ForEach(screenShots.indices, id: \.self) { index in
                                let image = screenShots[index]
                                let id = UUID()
                                
                                ZStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedImages.contains(id) ? Color.blue : Color.clear, lineWidth: 3)
                                        )
                                    
                                    if selectedImages.contains(id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                            .padding(8)
                                            .background(Circle().fill(Color.white))
                                            .shadow(radius: 2)
                                            .position(x: 30, y: 30)
                                    }
                                }
                                .onTapGesture {
                                    if selectedImages.contains(id) {
                                        selectedImages.remove(id)
                                    } else {
                                        selectedImages.insert(id)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: addSelectedScreenshots) {
                            Text("Add Selected to Style Board")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedImages.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(selectedImages.isEmpty)
                        
                        Button(action: {
                            screenShots = []
                            selectedImages = []
                        }) {
                            Text("Clear All")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add from Screenshots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            screenShots.append(image)
                            // Auto-select the newly added image
                            selectedImages.insert(UUID())
                        }
                    }
                }
            }
            .overlay {
                if isProcessing {
                    VStack {
                        ProgressView()
                        Text(processingMessage)
                            .padding(.top, 8)
                    }
                    .frame(width: 200, height: 100)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    private func addSelectedScreenshots() {
        guard !selectedImages.isEmpty, !screenShots.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            defer { isProcessing = false }
            
            // Process each selected screenshot
            for (index, id) in selectedImages.enumerated() {
                let image = screenShots[index % screenShots.count]
                
                processingMessage = "Processing screenshot \(index + 1) of \(selectedImages.count)..."
                
                // Check if it's a screenshot using ML
                let isScreenshot = await StyleAnalysisService.shared.detectAndProcessScreenshot(image)
                
                if isScreenshot {
                    // Save image to disk
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
                    
                    // Create a temporary file path
                    let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                    let fileName = "\(UUID().uuidString).jpg"
                    let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
                    
                    try? imageData.write(to: fileURL)
                    
                    // Create board item
                    let newItem = StyleBoardItem(
                        imageURL: fileURL,
                        sourceType: .screenshot,
                        board: board
                    )
                    
                    // Analyze the image
                    do {
                        let analysisService = StyleAnalysisService.shared
                        let result = try await analysisService.analyzeImage(image)
                        
                        newItem.detectedColors = result.dominantColors
                        newItem.detectedStyles = result.detectedStyles
                        newItem.detectedItems = result.detectedItems
                        newItem.mlConfidence = result.confidence
                        
                        await MainActor.run {
                            board.addInspiration(newItem)
                        }
                    } catch {
                        print("Error analyzing image: \(error)")
                        await MainActor.run {
                            board.addInspiration(newItem)
                        }
                    }
                }
            }
            
            // Update board style data
            processingMessage = "Finalizing style board..."
            try? await StyleAnalysisService.shared.analyzeBoard(board)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    AddFromScreenshotView(board: StyleBoard(name: "Test Board"))
        .modelContainer(for: [StyleBoard.self, StyleBoardItem.self])
} 