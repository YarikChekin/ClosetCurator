# ClosetCurator

An intelligent iOS app that digitizes your closet and provides personalized outfit recommendations based on weather and style preferences.

## Features

- 📸 **Closet Digitization**
  - AI-powered clothing item detection using Vision/Core ML
  - Automatic categorization of clothing items
  - Smart tagging and metadata extraction

- 🌤️ **Weather-Aware Recommendations**
  - Integration with weather services for forecast data
  - Temperature-appropriate outfit suggestions

- 👔 **Smart Outfit Management**
  - AI-powered outfit recommendations
  - Style preference learning
  - Outfit history and favorites
  - Seasonal outfit organization

- 🔄 **Feedback Loop**
  - User feedback on recommendations
  - Style preference refinement

## Technical Stack

- **Frontend**: SwiftUI (iOS 17+)
- **AI/ML**: Vision, Core ML
- **Data Persistence**: SwiftData
- **Architecture**: SwiftUI + SwiftData
- **Networking**: Async/Await, URLSession
- **Testing**: XCTest, XCUITest

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
ClosetCurator/
├── ClosetCuratorApp.swift (Main app entry point)
├── Features/
│   ├── Closet/
│   │   └── Views/
│   ├── Outfits/
│   │   └── Views/
│   └── Recommendations/
│       └── Views/
├── Core/
│   ├── ML/
│   │   └── ClothingDetectionService.swift
│   ├── Data/
│   │   └── Models/
│   │       ├── ClothingItem.swift
│   │       └── Outfit.swift
│   └── Services/
│       ├── ImageService.swift
│       └── WeatherService.swift
└── Views/
    └── ContentView.swift
```

## Getting Started

1. Clone the repository
2. Open `ClosetCurator.xcodeproj` in Xcode
3. Build and run the project

## Key Features Implementation

### SwiftData Models
The app uses SwiftData for persistence, with `ClothingItem` and `Outfit` as the main model objects with bidirectional relationships.

### Image Processing
`ImageService` handles saving and retrieving images for clothing items.

### ML Classification
`ClothingDetectionService` provides basic clothing item detection (currently uses mock data, but can be extended to use a real ML model).

### Weather-Based Recommendations
The app filters outfits based on temperature suitability using the `WeatherService`.

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

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 