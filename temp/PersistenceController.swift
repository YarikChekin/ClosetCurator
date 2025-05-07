import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleItem = ClothingItem(context: viewContext)
        sampleItem.id = UUID()
        sampleItem.name = "Sample T-Shirt"
        sampleItem.category = ClothingCategory.tops.rawValue
        sampleItem.dateAdded = Date()
        sampleItem.weatherTags = [WeatherTag.warm.rawValue]
        
        let sampleOutfit = Outfit(context: viewContext)
        sampleOutfit.id = UUID()
        sampleOutfit.name = "Sample Summer Outfit"
        sampleOutfit.dateCreated = Date()
        sampleOutfit.weatherTags = [WeatherTag.warm.rawValue, WeatherTag.hot.rawValue]
        sampleOutfit.items = [sampleItem]
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ClosetCurator")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
} 