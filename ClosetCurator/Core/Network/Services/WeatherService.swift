import Foundation
import CoreLocation

@MainActor
final class WeatherService: ObservableObject {
    // Our serializable weather info - this is what the app should use
    @Published var currentWeatherInfo: WeatherInfo?
    @Published var hourlyForecast: [WeatherInfo] = []
    @Published var dailyForecast: [WeatherInfo] = []
    @Published var error: Error?
    
    // For simulating location updates
    private let locationManager = CLLocationManager()
    
    init() {
        // In a real app, you would set up location permissions here
        // For now, we'll just use mock data
        setupMockWeather()
    }
    
    private func setupMockWeather() {
        // Create mock current weather
        currentWeatherInfo = WeatherInfo(
            temperature: 22.5,
            condition: .sunny,
            humidity: 65.0,
            windSpeed: 10.0,
            feelsLike: 23.0,
            minTemperature: 20.0,
            maxTemperature: 25.0
        )
        
        // Create mock hourly forecast
        hourlyForecast = [
            WeatherInfo(temperature: 22.0, condition: .sunny, feelsLike: 23.0),
            WeatherInfo(temperature: 23.0, condition: .sunny, feelsLike: 24.0),
            WeatherInfo(temperature: 23.5, condition: .partlyCloudy, feelsLike: 24.5),
            WeatherInfo(temperature: 24.0, condition: .cloudy, feelsLike: 25.0),
            WeatherInfo(temperature: 23.0, condition: .cloudy, feelsLike: 24.0),
            WeatherInfo(temperature: 22.0, condition: .partlyCloudy, feelsLike: 23.0),
            WeatherInfo(temperature: 21.0, condition: .partlyCloudy, feelsLike: 22.0)
        ]
        
        // Create mock daily forecast
        dailyForecast = [
            WeatherInfo(temperature: 22.5, condition: .sunny, minTemperature: 18.0, maxTemperature: 25.0),
            WeatherInfo(temperature: 24.0, condition: .partlyCloudy, minTemperature: 19.0, maxTemperature: 26.0),
            WeatherInfo(temperature: 23.0, condition: .cloudy, minTemperature: 18.0, maxTemperature: 24.0),
            WeatherInfo(temperature: 20.0, condition: .rainy, minTemperature: 16.0, maxTemperature: 22.0),
            WeatherInfo(temperature: 21.0, condition: .partlyCloudy, minTemperature: 17.0, maxTemperature: 23.0)
        ]
    }
    
    // This function would fetch real weather from an API in a production app
    func fetchWeather(for location: CLLocation) async {
        // In a real app, this would call a weather API
        // For development, we'll just use mock data
        // We already set up mock data in init(), but this simulates a delay
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // We'll just use our existing mock data
            // In a real app, this is where you'd parse API response
            
            // If we want to simulate different weather for different locations,
            // we could use the location parameter to vary the mock data
            
            // For example, we could vary the temperature based on latitude
            if let currentTemp = currentWeatherInfo?.temperature {
                let latitudeAdjustment = (location.coordinate.latitude - 40.0) * 0.5
                let newTemp = currentTemp + latitudeAdjustment
                currentWeatherInfo?.temperature = newTemp
                currentWeatherInfo?.feelsLike = newTemp + 1.0
            }
            
        } catch {
            self.error = error
        }
    }
    
    func getCurrentTemperature() -> Double? {
        return currentWeatherInfo?.temperature
    }
    
    func getCurrentConditions() -> Set<WeatherCondition> {
        guard let condition = currentWeatherInfo?.condition else { return [] }
        return [condition]
    }
    
    func getTemperatureRange() -> ClosedRange<Double>? {
        guard let min = currentWeatherInfo?.minTemperature,
              let max = currentWeatherInfo?.maxTemperature else {
            return nil
        }
        return min...max
    }
    
    // Convert WeatherCondition to WeatherTag for ClothingItem compatibility
    func convertToWeatherTags(from conditions: Set<WeatherCondition>, temperature: Double?) -> [WeatherTag] {
        var tags: [WeatherTag] = []
        
        // Add temperature-based tags
        if let temp = temperature {
            if temp >= 30 {
                tags.append(.hot)
            } else if temp >= 20 {
                tags.append(.warm)
            } else if temp >= 10 {
                tags.append(.cool)
            } else {
                tags.append(.cold)
            }
        }
        
        // Add condition-based tags
        if conditions.contains(.rainy) {
            tags.append(.rainy)
        }
        
        if conditions.contains(.snowy) {
            tags.append(.snowy)
        }
        
        return tags
    }
} 