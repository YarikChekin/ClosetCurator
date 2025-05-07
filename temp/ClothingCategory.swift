import Foundation

enum ClothingCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case tops = "tops"
    case bottoms = "bottoms"
    case dresses = "dresses"
    case outerwear = "outerwear"
    case shoes = "shoes"
    case accessories = "accessories"
    
    var id: String { rawValue }
} 