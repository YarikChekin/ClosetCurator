import SwiftUI

struct CreateOutfitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ClosetViewModel
    
    @State private var name = ""
    @State private var selectedItems: Set<ClothingItem> = []
    @State private var selectedWeatherTags: Set<WeatherTag> = []
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                
                Section("Weather Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(WeatherTag.allCases, id: \.self) { tag in
                                Button {
                                    if selectedWeatherTags.contains(tag) {
                                        selectedWeatherTags.remove(tag)
                                    } else {
                                        selectedWeatherTags.insert(tag)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: tag.systemImage)
                                        Text(tag.rawValue.capitalized)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedWeatherTags.contains(tag) ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedWeatherTags.contains(tag) ? .white : .primary)
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Select Items") {
                    ForEach(ClothingCategory.allCases) { category in
                        DisclosureGroup(category.rawValue.capitalized) {
                            ForEach(viewModel.clothingItems.filter { $0.category == category }) { item in
                                HStack {
                                    if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 44, height: 44)
                                            .cornerRadius(8)
                                    }
                                    
                                    Text(item.name ?? "Unnamed Item")
                                    
                                    Spacer()
                                    
                                    if selectedItems.contains(item) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedItems.contains(item) {
                                        selectedItems.remove(item)
                                    } else {
                                        selectedItems.insert(item)
                                    }
                                }
                            }
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
            .navigationTitle("Create Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createOutfit()
                    }
                    .disabled(name.isEmpty || selectedItems.isEmpty)
                }
            }
        }
    }
    
    private func createOutfit() {
        do {
            try viewModel.createOutfit(name: name,
                                     items: Array(selectedItems),
                                     weatherTags: Array(selectedWeatherTags))
            dismiss()
        } catch {
            self.error = "Failed to create outfit: \(error.localizedDescription)"
        }
    }
}

#Preview {
    CreateOutfitView(viewModel: ClosetViewModel(context: PersistenceController.preview.container.viewContext))
} 