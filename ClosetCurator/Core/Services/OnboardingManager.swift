import Foundation
import SwiftUI

final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") private(set) var hasCompletedOnboarding: Bool = false
    @AppStorage("onboardingStep") private(set) var currentStep: Int = 0
    
    var totalSteps: Int { 4 } // Welcome, Style, Closet, Permissions
    
    private init() {
        DebugLogger.info("OnboardingManager initialized")
        DebugLogger.info("Onboarding status: \(hasCompletedOnboarding ? "completed" : "not completed")")
        DebugLogger.info("Current step: \(currentStep) of \(totalSteps)")
    }
    
    func startOnboarding() {
        hasCompletedOnboarding = false
        currentStep = 0
        DebugLogger.info("Starting onboarding process")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentStep = 0
        DebugLogger.info("Onboarding completed")
    }
    
    func moveToNextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
            DebugLogger.info("Moving to onboarding step \(currentStep) of \(totalSteps)")
        } else {
            completeOnboarding()
        }
    }
    
    func moveToPreviousStep() {
        if currentStep > 0 {
            currentStep -= 1
            DebugLogger.info("Moving back to onboarding step \(currentStep) of \(totalSteps)")
        }
    }
    
    func skipToEnd() {
        DebugLogger.info("Skipping onboarding")
        completeOnboarding()
    }
} 