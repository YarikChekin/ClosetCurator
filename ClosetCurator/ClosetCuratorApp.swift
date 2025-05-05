import SwiftUI
import SwiftData
import UserNotifications

@main
struct ClosetCuratorApp: App {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingManager.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .onAppear {
                // Request notification permissions
                requestNotificationPermissions()
            }
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
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
} 