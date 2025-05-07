import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    private let service = WeatherService.shared
    @Published var currentWeather: Weather?
    @Published var error: Error?
    
    func fetchWeather(for location: CLLocation) async {
        do {
            currentWeather = try await service.weather(for: location)
        } catch {
            self.error = error
        }
    }
    
    func getWeatherTags(for weather: Weather) -> [WeatherTag] {
        var tags: [WeatherTag] = []
        let temperature = weather.currentWeather.temperature.value
        
        // Temperature-based tags
        switch temperature {
        case ..<10:
            tags.append(.cold)
        case 10..<18:
            tags.append(.cool)
        case 18..<25:
            tags.append(.warm)
        default:
            tags.append(.hot)
        }
        
        // Weather condition tags
        switch weather.currentWeather.condition {
        case .rain, .drizzle, .freezingDrizzle:
            tags.append(.rainy)
        case .snow, .sleet, .hail:
            tags.append(.snowy)
        default:
            break
        }
        
        return tags
    }
} 