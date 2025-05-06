import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherService: ObservableObject {
    private let weatherService = WeatherService.shared
    @Published var currentWeather: Weather?
    @Published var hourlyForecast: [HourWeather] = []
    @Published var dailyForecast: [DayWeather] = []
    @Published var error: Error?
    
    // Our serializable weather info
    @Published var currentWeatherInfo: WeatherInfo?
    
    func fetchWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
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
        guard let currentWeather = weather.currentWeather else {
            return WeatherInfo(condition: .unknown)
        }
        
        // Map WeatherKit condition to our condition
        let condition: WeatherInfo.WeatherCondition
        switch currentWeather.condition {
        case .clear:
            condition = .sunny
        case .cloudy, .mostlyCloudy:
            condition = .cloudy
        case .partlyCloudy, .mostlyClear:
            condition = .partlyCloudy
        case .rain, .heavyRain, .drizzle, .showers:
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
            temperature: currentWeather.temperature.value,
            condition: condition,
            humidity: currentWeather.humidity,
            windSpeed: currentWeather.wind.speed.value,
            feelsLike: currentWeather.apparentTemperature.value,
            minTemperature: dailyForecast.first?.lowTemperature.value,
            maxTemperature: dailyForecast.first?.highTemperature.value
        )
    }
    
    func getCurrentTemperature() -> Double? {
        currentWeather?.currentWeather.temperature.value
    }
    
    func getCurrentConditions() -> Set<ClothingItem.WeatherCondition> {
        guard let current = currentWeather?.currentWeather else { return [] }
        
        var conditions: Set<ClothingItem.WeatherCondition> = []
        
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
    
    func getWeatherConditions(for hours: Int = 24) -> Set<ClothingItem.WeatherCondition> {
        guard !hourlyForecast.isEmpty else { return [] }
        
        let relevantForecast = Array(hourlyForecast.prefix(hours))
        var conditions: Set<ClothingItem.WeatherCondition> = []
        
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
} 