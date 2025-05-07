import SwiftUI
import SwiftData

struct CreateStyleBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var stylePreferences: [StylePreference]
    
    @State private var name = ""
    @State private var description = ""
    @State private var season: Season?
    @State private var occasion: Occasion?
    @State private var mood = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Board Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Style Context") {
                    Picker("Season", selection: $season) {
                        Text("None").tag(nil as Season?)
                        ForEach(Season.allCases, id: \.self) { season in
                            Text(season.rawValue.capitalized).tag(season as Season?)
                        }
                    }
                    
                    Picker("Occasion", selection: $occasion) {
                        Text("None").tag(nil as Occasion?)
                        ForEach(Occasion.allCases, id: \.self) { occasion in
                            Text(occasion.rawValue.capitalized).tag(occasion as Occasion?)
                        }
                    }
                    
                    TextField("Mood or Theme", text: $mood)
                }
                
                Section("Style Learning") {
                    Text("This board will contribute to your style preferences and help generate better outfit recommendations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Style Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(minWidth: DesignTokens.minTappable, minHeight: DesignTokens.minTappable)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createStyleBoard()
                    }
                    .disabled(name.isEmpty)
                    .frame(minWidth: DesignTokens.minTappable, minHeight: DesignTokens.minTappable)
                }
            }
        }
    }
    
    private func createStyleBoard() {
        // Get or create user style preference
        let preference: StylePreference
        if let existingPreference = stylePreferences.first {
            preference = existingPreference
        } else {
            // Create new style preference if none exists
            preference = StylePreference()
            modelContext.insert(preference)
        }
        
        // Create the style board
        let newBoard = StyleBoard(
            name: name,
            description: description.isEmpty ? nil : description,
            season: season,
            occasion: occasion,
            mood: mood.isEmpty ? nil : mood,
            preference: preference
        )
        
        modelContext.insert(newBoard)
        dismiss()
    }
}

#Preview {
    CreateStyleBoardView()
        .modelContainer(for: [StyleBoard.self, StylePreference.self])
} 