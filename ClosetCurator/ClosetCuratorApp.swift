import SwiftUI
import SwiftData

@main
struct ClosetCuratorApp: App {
    @StateObject private var weatherService = WeatherService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            ClothingItem.self,
            Outfit.self,
            StylePreference.self,
            StyleBoard.self,
            StyleBoardItem.self,
            StyleFeedback.self
        ])
    }
} 