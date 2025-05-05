import SwiftUI
import SwiftData
import PhotosUI

struct StyleBoardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var board: StyleBoard
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingAddFromScreenshot = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 8)
    ]
    
    var body: some View {
        ScrollView {
            // Board stats and insights
            VStack(alignment: .leading, spacing: 16) {
                // Board info
                VStack(alignment: .leading, spacing: 8) {
                    if let description = board.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                    }
                    
                    HStack {
                        if let season = board.season {
                            Label(season.rawValue.capitalized, systemImage: "leaf")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        if let occasion = board.occasion {
                            Label(occasion.rawValue.capitalized, systemImage: "calendar")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding(.horizontal)
                
                // Board insights
                if !board.dominantColors.isEmpty || !board.detectedStyles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Style Insights")
                            .font(.headline)
                        
                        if !board.dominantColors.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Colors")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(board.dominantColors, id: \.self) { color in
                                            Text(color)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.gray.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !board.detectedStyles.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Styles")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(board.detectedStyles, id: \.self) { style in
                                            Text(style.rawValue.capitalized)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.indigo.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                
                // Board items
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(board.items) { item in
                        StyleBoardItemView(item: item)
                            .contextMenu {
                                Button(role: .destructive) {
                                    board.removeInspiration(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    // Add like rating
                                    item.userLikeScore = (item.userLikeScore ?? 0) + 1
                                } label: {
                                    Label("Like", systemImage: "heart")
                                }
                                
                                Button {
                                    // Add tag
                                    // (In a real app, show a dialog)
                                    item.userTags.append("Favorite")
                                } label: {
                                    Label("Tag as Favorite", systemImage: "tag")
                                }
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(board.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    
                    Button {
                        showingAddFromScreenshot = true
                    } label: {
                        Label("Add from Screenshot", systemImage: "rectangle.and.paperclip")
                    }
                } label: {
                    Label("Add Inspiration", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("Select Photo")
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $selectedImage)
        }
        .sheet(isPresented: $showingAddFromScreenshot) {
            AddFromScreenshotView(board: board)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                addImageToBoard(image, source: .camera)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        addImageToBoard(image, source: .photoLibrary)
                    }
                }
            }
        }
        .overlay {
            if isAnalyzing {
                VStack {
                    ProgressView()
                    Text("Analyzing image...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
                .ignoresSafeArea()
            }
        }
    }
    
    private func addImageToBoard(_ image: UIImage, source: StyleBoardItem.SourceType) {
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            
            // Save image to disk
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            
            // Create a temporary file path
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
            
            try? imageData.write(to: fileURL)
            
            // Create board item
            let newItem = StyleBoardItem(
                imageURL: fileURL,
                sourceType: source,
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
                
                board.addInspiration(newItem)
                
                // Update board style data
                try await analysisService.analyzeBoard(board)
            } catch {
                print("Error analyzing image: \(error)")
                board.addInspiration(newItem)
            }
        }
    }
}

struct StyleBoardItemView: View {
    let item: StyleBoardItem
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let imageURL = item.imageURL, let uiImage = loadImage(from: imageURL) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let likeScore = item.userLikeScore, likeScore > 0 {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .padding(8)
            }
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

#Preview {
    // Create a sample style board for preview
    NavigationStack {
        StyleBoardDetailView(board: StyleBoard(
            name: "Summer Vibes",
            description: "Light and airy summer styles",
            season: .summer,
            occasion: .casual,
            items: []
        ))
    }
    .modelContainer(for: [StyleBoard.self, StyleBoardItem.self])
} 