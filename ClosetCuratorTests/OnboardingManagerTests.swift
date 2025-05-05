import XCTest
@testable import ClosetCurator

final class OnboardingManagerTests: XCTestCase {
    var onboardingManager: OnboardingManager!
    
    override func setUp() {
        super.setUp()
        // Create a fresh instance for each test
        onboardingManager = OnboardingManager()
        
        // Reset state
        onboardingManager.hasCompletedOnboarding = false
        onboardingManager.currentStep = 0
    }
    
    override func tearDown() {
        onboardingManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Test that the initial state is correctly set
        XCTAssertFalse(onboardingManager.hasCompletedOnboarding)
        XCTAssertEqual(onboardingManager.currentStep, 0)
        XCTAssertEqual(onboardingManager.totalSteps, 4)
    }
    
    func testStartOnboarding() {
        // Set up a completed state first
        onboardingManager.hasCompletedOnboarding = true
        onboardingManager.currentStep = 2
        
        // Start onboarding should reset to initial state
        onboardingManager.startOnboarding()
        
        XCTAssertFalse(onboardingManager.hasCompletedOnboarding)
        XCTAssertEqual(onboardingManager.currentStep, 0)
    }
    
    func testCompleteOnboarding() {
        // Test that onboarding can be completed
        onboardingManager.completeOnboarding()
        
        XCTAssertTrue(onboardingManager.hasCompletedOnboarding)
        XCTAssertEqual(onboardingManager.currentStep, 0)
    }
    
    func testMoveToNextStep() {
        // Test moving forward through steps
        onboardingManager.moveToNextStep()
        XCTAssertEqual(onboardingManager.currentStep, 1)
        
        onboardingManager.moveToNextStep()
        XCTAssertEqual(onboardingManager.currentStep, 2)
        
        onboardingManager.moveToNextStep()
        XCTAssertEqual(onboardingManager.currentStep, 3)
        
        // Should complete onboarding after the last step
        onboardingManager.moveToNextStep()
        XCTAssertTrue(onboardingManager.hasCompletedOnboarding)
    }
    
    func testMoveToPreviousStep() {
        // Start at step 3
        onboardingManager.currentStep = 3
        
        // Test moving backward through steps
        onboardingManager.moveToPreviousStep()
        XCTAssertEqual(onboardingManager.currentStep, 2)
        
        onboardingManager.moveToPreviousStep()
        XCTAssertEqual(onboardingManager.currentStep, 1)
        
        onboardingManager.moveToPreviousStep()
        XCTAssertEqual(onboardingManager.currentStep, 0)
        
        // Should not go below 0
        onboardingManager.moveToPreviousStep()
        XCTAssertEqual(onboardingManager.currentStep, 0)
    }
    
    func testSkipToEnd() {
        // Test that skipping completes onboarding
        onboardingManager.skipToEnd()
        
        XCTAssertTrue(onboardingManager.hasCompletedOnboarding)
    }
} 