import Foundation
import SwiftUI

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("onboardingStep") var currentStep: Int = 0
    
    var totalSteps: Int { 4 } // Welcome, Style, Closet, Permissions
    
    func startOnboarding() {
        hasCompletedOnboarding = false
        currentStep = 0
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentStep = 0
    }
    
    func moveToNextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            completeOnboarding()
        }
    }
    
    func moveToPreviousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    func skipToEnd() {
        completeOnboarding()
    }
} 