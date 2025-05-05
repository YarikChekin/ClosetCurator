import Foundation
import CoreData

@objc(ClothingItem)
public class ClothingItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var category: String
    @NSManaged public var imageData: Data?
    @NSManaged public var weatherTags: [String]
    @NSManaged public var dateAdded: Date
    @NSManaged public var lastWorn: Date?
    @NSManaged public var outfit: Outfit?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        dateAdded = Date()
        weatherTags = []
    }
}

extension ClothingItem {
    static func fetchRequest() -> NSFetchRequest<ClothingItem> {
        return NSFetchRequest<ClothingItem>(entityName: "ClothingItem")
    }
    
    var formattedDateAdded: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateAdded)
    }
    
    var formattedLastWorn: String? {
        guard let lastWorn = lastWorn else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: lastWorn)
    }
} 