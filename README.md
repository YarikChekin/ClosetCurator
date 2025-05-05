# ClosetCurator

An intelligent iOS app that digitizes your closet and provides personalized outfit recommendations based on weather and style preferences.

## Features

- 📸 **Closet Digitization**
  - AI-powered clothing item detection using Vision/Core ML
  - Automatic categorization of clothing items
  - Smart tagging and metadata extraction

- 🌤️ **Weather-Aware Recommendations**
  - Integration with WeatherKit for real-time weather data
  - Location-based weather forecasts
  - Temperature-appropriate outfit suggestions

- 👔 **Smart Outfit Management**
  - AI-powered outfit recommendations
  - Style preference learning
  - Outfit history and favorites
  - Seasonal outfit organization

- 🔄 **Feedback Loop**
  - User feedback on recommendations
  - Style preference refinement
  - Machine learning model improvement

## Technical Stack

- **Frontend**: SwiftUI (iOS 17+)
- **AI/ML**: Vision, Core ML
- **Weather**: WeatherKit
- **Data Persistence**: SwiftData
- **Networking**: Async/Await, URLSession
- **Testing**: XCTest, XCUITest

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer Account (for WeatherKit)

## Project Structure

```
ClosetCurator/
├── App/
│   ├── ClosetCuratorApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── Closet/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   ├── Outfits/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   ├── Weather/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Services/
│   └── Recommendations/
│       ├── Views/
│       ├── ViewModels/
│       └── Services/
├── Core/
│   ├── ML/
│   │   ├── Models/
│   │   └── Services/
│   ├── Data/
│   │   ├── Models/
│   │   └── Services/
│   └── Network/
│       └── Services/
└── Utils/
    ├── Extensions/
    └── Helpers/
```

## Getting Started

1. Clone the repository
2. Open `ClosetCurator.xcodeproj` in Xcode
3. Set up your Apple Developer account credentials
4. Configure WeatherKit in your Apple Developer account
5. Build and run the project

## Development Setup

1. Install required dependencies:
   ```bash
   brew install swiftlint
   ```

2. Set up pre-commit hooks:
   ```bash
   git config core.hooksPath .githooks
   ```

3. Configure Xcode:
   - Enable "All" warnings
   - Set up code signing
   - Configure WeatherKit capabilities

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 