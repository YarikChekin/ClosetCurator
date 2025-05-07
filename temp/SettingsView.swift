import SwiftUI

struct SettingsView: View {
    @AppStorage("useMetricSystem") private var useMetricSystem = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("dailyRecommendationTime") private var dailyRecommendationTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Units") {
                    Toggle("Use Metric System", isOn: $useMetricSystem)
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    if enableNotifications {
                        DatePicker("Daily Recommendation Time",
                                 selection: $dailyRecommendationTime,
                                 displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yarikchekin/ClosetCurator")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:support@closetcurator.app")!) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        // TODO: Implement data reset
                    } label: {
                        Text("Reset All Data")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
} 