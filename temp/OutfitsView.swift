import SwiftUI

struct OutfitsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    @State private var showingCreateOutfit = false
    @State private var selectedWeatherFilter: WeatherTag?
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ClosetViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button {
                            selectedWeatherFilter = nil
                        } label: {
                            Text("All")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedWeatherFilter == nil ? Color.accentColor : Color.gray.opacity(0.2))
                                .foregroundColor(selectedWeatherFilter == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(WeatherTag.allCases, id: \.self) { tag in
                            Button {
                                selectedWeatherFilter = tag
                            } label: {
                                HStack {
                                    Image(systemName: tag.systemImage)
                                    Text(tag.rawValue.capitalized)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedWeatherFilter == tag ? Color.accentColor : Color.gray.opacity(0.2))
                                .foregroundColor(selectedWeatherFilter == tag ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                
                List {
                    ForEach(viewModel.outfits.filter { outfit in
                        guard let filter = selectedWeatherFilter else { return true }
                        return outfit.weatherTags?.contains(filter) ?? false
                    }) { outfit in
                        OutfitRow(outfit: outfit)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteOutfit(outfit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("My Outfits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateOutfit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateOutfit) {
                CreateOutfitView(viewModel: viewModel)
            }
        }
    }
}

struct OutfitRow: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(outfit.name ?? "Unnamed Outfit")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(outfit.items?.allObjects as? [ClothingItem] ?? [], id: \.id) { item in
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            HStack {
                ForEach(outfit.weatherTags ?? [], id: \.self) { tag in
                    Image(systemName: tag.systemImage)
                        .foregroundColor(tag.color)
                }
                
                Spacer()
                
                if let lastWorn = outfit.lastWorn {
                    Text("Last worn: \(lastWorn.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OutfitsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 