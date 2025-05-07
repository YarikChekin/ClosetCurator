import SwiftUI
import SwiftData
import UserNotifications

@main
struct ClosetCuratorApp: App {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    init() {
        DebugLogger.info("Application initializing")
        
        // Log Swift and SwiftData versions
        DebugLogger.info("Swift version: \(String(describing: ProcessInfo().operatingSystemVersionString))")
        DebugLogger.info("Device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingManager.hasCompletedOnboarding {
                    DebugLogger.info("Loading main ContentView")
                    ContentView()
                } else {
                    DebugLogger.info("Loading OnboardingView")
                    OnboardingView()
                }
            }
            .onAppear {
                DebugLogger.info("Main view appeared")
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
        ], isStoredInMemoryOnly: false)
        .onAppear {
            DebugLogger.info("Model container initialized with persistent storage")
        }
    }
    
    private func requestNotificationPermissions() {
        DebugLogger.info("Requesting notification permissions")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                DebugLogger.error("Error requesting notification authorization: \(error)")
            } else {
                DebugLogger.info("Notification authorization status: \(success ? "granted" : "denied")")
            }
        }
    }
} 