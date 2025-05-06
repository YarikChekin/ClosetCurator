import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherService: ObservableObject {
    // Using Apple's WeatherKit service
    private let weatherKitService = WeatherKit.WeatherService()
    
    @Published var currentWeather: Weather?
    @Published var hourlyForecast: [HourWeather] = []
    @Published var dailyForecast: [DayWeather] = []
    @Published var error: Error?
    
    // Our serializable weather info
    @Published var currentWeatherInfo: WeatherInfo?
    
    func fetchWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherKitService.weather(for: location)
            currentWeather = weather
            hourlyForecast = Array(weather.hourlyForecast.forecast.prefix(24))
            dailyForecast = Array(weather.dailyForecast.forecast.prefix(7))
            
            // Convert to our WeatherInfo type
            currentWeatherInfo = convertToWeatherInfo(from: weather)
        } catch {
            self.error = error
        }
    }
    
    private func convertToWeatherInfo(from weather: Weather) -> WeatherInfo {
        // CurrentWeather is not optional in WeatherKit's Weather
        let weatherCurrent = weather.currentWeather
        
        // Map WeatherKit condition to our condition
        let condition: WeatherInfo.WeatherCondition
        switch weatherCurrent.condition {
        case .clear:
            condition = .sunny
        case .cloudy, .mostlyCloudy:
            condition = .cloudy
        case .partlyCloudy, .mostlyClear:
            condition = .partlyCloudy
        case .rain, .heavyRain, .drizzle:
            condition = .rainy
        case .snow, .sleet, .hail, .wintryMix, .flurries:
            condition = .snowy
        case .windy, .breezy:
            condition = .windy
        case .foggy, .haze:
            condition = .foggy
        case .thunderstorms:
            condition = .stormy
        default:
            condition = .unknown
        }
        
        return WeatherInfo(
            temperature: weatherCurrent.temperature.value,
            condition: condition,
            humidity: weatherCurrent.humidity,
            windSpeed: weatherCurrent.wind.speed.value,
            feelsLike: weatherCurrent.apparentTemperature.value,
            minTemperature: dailyForecast.first?.lowTemperature.value,
            maxTemperature: dailyForecast.first?.highTemperature.value
        )
    }
    
    func getCurrentTemperature() -> Double? {
        currentWeather?.currentWeather.temperature.value
    }
    
    func getCurrentConditions() -> Set<WeatherCondition> {
        guard let currentWeather = currentWeather else { return [] }
        
        // currentWeather is not nil, but currentWeather.currentWeather is not optional
        let current = currentWeather.currentWeather
        var conditions: Set<WeatherCondition> = []
        
        // Map WeatherKit conditions to our conditions
        if current.isDaylight {
            conditions.insert(.sunny)
        }
        
        switch current.condition {
        case .rain, .heavyRain, .drizzle:
            conditions.insert(.rainy)
        case .cloudy, .mostlyCloudy:
            conditions.insert(.cloudy)
        case .snow, .sleet, .hail:
            conditions.insert(.snowy)
        case .windy, .breezy:
            conditions.insert(.windy)
        default:
            break
        }
        
        return conditions
    }
    
    func getTemperatureRange(for hours: Int = 24) -> ClosedRange<Double>? {
        guard !hourlyForecast.isEmpty else { return nil }
        
        let relevantForecast = Array(hourlyForecast.prefix(hours))
        let temperatures = relevantForecast.map { $0.temperature.value }
        
        guard let minTemp = temperatures.min(),
              let maxTemp = temperatures.max() else {
            return nil
        }
        
        return minTemp...maxTemp
    }
    
    func getWeatherConditions(for hours: Int = 24) -> Set<WeatherCondition> {
        guard !hourlyForecast.isEmpty else { return [] }
        
        let relevantForecast = Array(hourlyForecast.prefix(hours))
        var conditions: Set<WeatherCondition> = []
        
        for forecast in relevantForecast {
            if forecast.isDaylight {
                conditions.insert(.sunny)
            }
            
            switch forecast.condition {
            case .rain, .heavyRain, .drizzle:
                conditions.insert(.rainy)
            case .cloudy, .mostlyCloudy:
                conditions.insert(.cloudy)
            case .snow, .sleet, .hail:
                conditions.insert(.snowy)
            case .windy, .breezy:
                conditions.insert(.windy)
            default:
                break
            }
        }
        
        return conditions
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