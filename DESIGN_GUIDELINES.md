# DESIGN GUIDELINES

We follow Apple's [Human Interface Guidelines (HIG)](https://developer.apple.com/design/human-interface-guidelines/) for all UI in Closet Curator. This ensures accessibility, consistency, and a native iOS experience.

## Key Principles

- **System Colors & Semantic Styles**: Use `.primary`, `.secondary`, `.accentColor`, etc. for text and backgrounds.
- **SF Symbols**: Use [SF Symbols](https://developer.apple.com/sf-symbols/) for all icons.
- **Dynamic Type**: Use text styles like `.largeTitle`, `.headline`, `.body`, `.caption` to support accessibility.
- **8-Point Grid**: Base all spacing, padding, and margins on multiples of 8 (8, 16, 24, 32…).
- **Tappable Areas**: All interactive elements must be at least 44×44 points.
- **Safe Area Insets**: Layouts must respect device safe areas.
- **Corner Radius**: Use a standard 10pt corner radius for cards and buttons.

## Sample Code Snippets

### Importing Design Tokens
```swift
import DesignTokens // Contains color, spacing, and style constants
```

### Verification Comment Example
```swift
// ✔ HIG: DynamicType .headline, 8pt padding, SF Symbol "star.fill"
```

### Example: Card View
```swift
// ✔ HIG: DynamicType .headline, 16pt padding, SF Symbol "tshirt.fill"
import DesignTokens

struct ClothingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
            Text("T-Shirt")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}
```

### Example: Button
```swift
// ✔ HIG: DynamicType .body, 8pt padding, SF Symbol "plus"
import DesignTokens

Button(action: { /* ... */ }) {
    Label("Add Item", systemImage: "plus")
        .font(.body)
        .padding(8)
        .frame(minWidth: 44, minHeight: 44)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(10)
}
```

### Example: Respecting Safe Area
```swift
// ✔ HIG: Safe area insets, 16pt padding
import DesignTokens

struct ContentView: View {
    var body: some View {
        VStack {
            // ...
        }
        .padding(16)
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
    }
}
```

---

For more, see the [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/). 