import Foundation
import CoreData

@objc(Outfit)
public class Outfit: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var items: Set<ClothingItem>
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        dateCreated = Date()
    }
}

extension Outfit {
    static func fetchRequest() -> NSFetchRequest<Outfit> {
        return NSFetchRequest<Outfit>(entityName: "Outfit")
    }
    
    var formattedDateCreated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateCreated)
    }
    
    func addToItems(_ item: ClothingItem) {
        var items = self.items
        items.insert(item)
        self.items = items
    }
    
    func removeFromItems(_ item: ClothingItem) {
        var items = self.items
        items.remove(item)
        self.items = items
    }
} 