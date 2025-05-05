import SwiftUI
import SwiftData
import UserNotifications
import CoreLocation

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            TabView(selection: $onboardingManager.currentStep) {
                // Step 0: Welcome Screen
                WelcomeView(onNext: onboardingManager.moveToNextStep)
                    .tag(0)
                
                // Step 1: Style Preferences
                StylePreferencesOnboardingView(onNext: onboardingManager.moveToNextStep, 
                                             onBack: onboardingManager.moveToPreviousStep)
                    .environment(\.modelContext, modelContext)
                    .tag(1)
                
                // Step 2: Initial Closet Setup
                ClosetSetupView(onNext: onboardingManager.moveToNextStep, 
                              onBack: onboardingManager.moveToPreviousStep)
                    .environment(\.modelContext, modelContext)
                    .tag(2)
                
                // Step 3: Permissions
                PermissionsView(onComplete: onboardingManager.completeOnboarding, 
                              onBack: onboardingManager.moveToPreviousStep)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: onboardingManager.currentStep)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topTrailing) {
                    Button("Skip") {
                        onboardingManager.skipToEnd()
                    }
                    .padding()
                }
            }
        }
    }
}

// The welcome screen
struct WelcomeView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "tshirt.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()
            
            Text("Welcome to ClosetCurator")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Your personal wardrobe assistant")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "tshirt", 
                    title: "Digitize Your Closet",
                    description: "Catalog your clothing items for easy outfit planning"
                )
                
                FeatureRow(
                    icon: "cloud.sun", 
                    title: "Weather-Based Recommendations",
                    description: "Get outfit suggestions based on current weather"
                )
                
                FeatureRow(
                    icon: "square.grid.2x2", 
                    title: "Style Boards",
                    description: "Create vision boards to inspire your personal style"
                )
                
                FeatureRow(
                    icon: "wand.and.stars", 
                    title: "Smart Recommendations",
                    description: "Personalized outfit ideas that learn from your preferences"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

// Style Preferences Onboarding View
struct StylePreferencesOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedStyles: [StyleTag] = []
    @State private var selectedColors: [String] = []
    @State private var adventureLevel: Double = 0.5
    let onNext: () -> Void
    let onBack: () -> Void
    
    private let availableColors = [
        "Black", "White", "Gray", "Navy", "Blue", 
        "Green", "Red", "Yellow", "Purple", "Pink", 
        "Brown", "Beige", "Orange", "Teal"
    ]
    
    var body: some View {
        VStack {
            Text("Style Preferences")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            Text("Tell us about your style preferences to get personalized recommendations")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Style Selection
                    Text("What styles do you prefer?")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    StyleTagsView(selectedStyles: $selectedStyles)
                        .padding(.horizontal)
                    
                    // Color Selection
                    Text("What colors do you like to wear?")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    ColorSelectionView(selectedColors: $selectedColors, availableColors: availableColors)
                        .padding(.horizontal)
                    
                    // Adventure Level
                    Text("How adventurous is your style?")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    VStack {
                        Slider(value: $adventureLevel, in: 0...1, step: 0.05)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Conservative")
                                .font(.caption)
                            Spacer()
                            Text("Adventurous")
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: {
                    savePreferences()
                    onNext()
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
    private func savePreferences() {
        // Create a new StylePreference with the selected values
        let newPreference = StylePreference(
            favoriteColors: selectedColors,
            favoriteStyles: selectedStyles,
            favoredBrands: [],
            favoredFits: [],
            adventureLevel: adventureLevel
        )
        
        // Save to the model context
        modelContext.insert(newPreference)
        try? modelContext.save()
    }
}

// Helper view for style tag selection
struct StyleTagsView: View {
    @Binding var selectedStyles: [StyleTag]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
            ForEach(StyleTag.allCases, id: \.self) { style in
                Button(action: {
                    toggleStyle(style)
                }) {
                    Text(style.rawValue.capitalized)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            selectedStyles.contains(style) ? 
                                Color.blue : Color.secondary.opacity(0.2)
                        )
                        .foregroundColor(
                            selectedStyles.contains(style) ? 
                                Color.white : Color.primary
                        )
                        .cornerRadius(20)
                }
            }
        }
    }
    
    private func toggleStyle(_ style: StyleTag) {
        if selectedStyles.contains(style) {
            selectedStyles.removeAll { $0 == style }
        } else {
            selectedStyles.append(style)
        }
    }
}

// Helper view for color selection
struct ColorSelectionView: View {
    @Binding var selectedColors: [String]
    let availableColors: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
            ForEach(availableColors, id: \.self) { color in
                Button(action: {
                    toggleColor(color)
                }) {
                    HStack {
                        Circle()
                            .fill(colorFromName(color))
                            .frame(width: 20, height: 20)
                        
                        Text(color)
                            .font(.caption)
                        
                        Spacer()
                        
                        if selectedColors.contains(color) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        selectedColors.contains(color) ? 
                            Color.blue.opacity(0.1) : Color.clear
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                selectedColors.contains(color) ? 
                                    Color.blue : Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func toggleColor(_ color: String) {
        if selectedColors.contains(color) {
            selectedColors.removeAll { $0 == color }
        } else {
            selectedColors.append(color)
        }
    }
    
    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "black": return .black
        case "white": return .white
        case "gray": return .gray
        case "navy": return Color(red: 0, green: 0, blue: 0.5)
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return Color(red: 0.6, green: 0.4, blue: 0.2)
        case "beige": return Color(red: 0.96, green: 0.96, blue: 0.86)
        case "orange": return .orange
        case "teal": return .teal
        default: return .gray
        }
    }
}

// Initial Closet Setup View
struct ClosetSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @Query private var clothingItems: [ClothingItem]
    
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            Text("Add Your First Items")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            Text("Get started by adding a few clothing items to your closet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
            
            if clothingItems.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("Your closet is empty")
                        .font(.headline)
                    
                    Text("Add some clothing items to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingAddItem = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Clothing Item")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                // Display added items
                VStack(alignment: .leading) {
                    HStack {
                        Text("Added Items (\(clothingItems.count))")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddItem = true }) {
                            Label("Add More", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    List {
                        ForEach(clothingItems) { item in
                            ClothingItemRow(item: item)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(height: 300)
                }
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: onNext) {
                    HStack {
                        Text(clothingItems.isEmpty ? "Skip" : "Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddItem) {
            AddClothingItemView()
        }
    }
}

// Permissions View
struct PermissionsView: View {
    @State private var locationAuthorized = false
    @State private var notificationsAuthorized = false
    let locationManager = CLLocationManager()
    
    let onComplete: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            Text("Final Setup")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            Text("Enable these permissions for the best experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
            
            VStack(spacing: 30) {
                PermissionCard(
                    icon: "location.fill",
                    title: "Location Access",
                    description: "Needed for accurate weather-based outfit recommendations",
                    isEnabled: locationAuthorized,
                    action: requestLocationPermission
                )
                
                PermissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get reminders about weather changes and outfit suggestions",
                    isEnabled: notificationsAuthorized,
                    action: requestNotificationPermission
                )
            }
            .padding()
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: onComplete) {
                    HStack {
                        Text("Get Started")
                        Image(systemName: "checkmark.circle")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .onAppear {
            checkLocationAuthorization()
            checkNotificationAuthorization()
        }
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationAuthorized = true
        default:
            locationAuthorized = false
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            checkLocationAuthorization()
        }
    }
    
    private func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            DispatchQueue.main.async {
                notificationsAuthorized = success
            }
        }
    }
}

// Helper view for displaying a permission card
struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: action) {
                    Text("Enable")
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

// Helper view for feature rows on the welcome screen
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [ClothingItem.self, StylePreference.self])
} 