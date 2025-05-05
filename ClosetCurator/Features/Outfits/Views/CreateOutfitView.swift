import SwiftUI
import SwiftData

struct CreateOutfitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    
    @State private var name = ""
    @State private var selectedItems = Set<ClothingItem>()
    @State private var notes = ""
    @State private var minTemperature: Double?
    @State private var maxTemperature: Double?
    @State private var selectedWeatherTags = Set<WeatherTag>()
    @State private var selectedStyleTags = Set<StyleTag>()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Outfit Details") {
                    TextField("Name", text: $name)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section("Weather Suitability") {
                    HStack {
                        Text("Min Temp (°C)")
                        Spacer()
                        TextField("Min", value: $minTemperature, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Max Temp (°C)")
                        Spacer()
                        TextField("Max", value: $maxTemperature, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Weather Tags")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(WeatherTag.allCases, id: \.self) { tag in
                                    Toggle(tag.rawValue.capitalized, isOn: Binding(
                                        get: { selectedWeatherTags.contains(tag) },
                                        set: { isOn in
                                            if isOn {
                                                selectedWeatherTags.insert(tag)
                                            } else {
                                                selectedWeatherTags.remove(tag)
                                            }
                                        }
                                    ))
                                    .toggleStyle(.button)
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                
                Section("Style") {
                    VStack(alignment: .leading) {
                        Text("Style Tags")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(StyleTag.allCases, id: \.self) { tag in
                                    Toggle(tag.rawValue.capitalized, isOn: Binding(
                                        get: { selectedStyleTags.contains(tag) },
                                        set: { isOn in
                                            if isOn {
                                                selectedStyleTags.insert(tag)
                                            } else {
                                                selectedStyleTags.remove(tag)
                                            }
                                        }
                                    ))
                                    .toggleStyle(.button)
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                
                Section("Select Items") {
                    ForEach(ClothingCategory.allCases, id: \.self) { category in
                        DisclosureGroup(category.rawValue.capitalized) {
                            let categoryItems = clothingItems.filter { $0.category == category }
                            ForEach(categoryItems) { item in
                                HStack {
                                    ClothingItemRowSmall(item: item)
                                    Spacer()
                                    Image(systemName: selectedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedItems.contains(item) ? .blue : .gray)
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
            }
            .navigationTitle("Create Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveOutfit()
                    }
                    .disabled(name.isEmpty || selectedItems.isEmpty)
                }
            }
        }
    }
    
    private func saveOutfit() {
        let outfit = Outfit(
            name: name,
            items: Array(selectedItems),
            dateCreated: Date(),
            notes: notes.isEmpty ? nil : notes,
            minTemperature: minTemperature,
            maxTemperature: maxTemperature,
            weatherTags: Array(selectedWeatherTags),
            styleTags: Array(selectedStyleTags)
        )
        
        modelContext.insert(outfit)
        dismiss()
    }
}

struct ClothingItemRowSmall: View {
    let item: ClothingItem
    
    var body: some View {
        HStack {
            if let imageURL = item.imageURL,
               let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "tshirt.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .padding(5)
                    .foregroundColor(.white)
                    .background(Color.gray)
                    .clipShape(Circle())
            }
            
            Text(item.name)
                .font(.subheadline)
        }
    }
}

#Preview {
    CreateOutfitView()
        .modelContainer(for: [ClothingItem.self, Outfit.self])
} 