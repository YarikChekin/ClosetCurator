import Foundation

/// A simple weather information model that can be persisted
struct WeatherInfo: Codable, Hashable, Equatable {
    var temperature: Double?
    var condition: WeatherCondition
    var humidity: Double?
    var windSpeed: Double?
    var feelsLike: Double?
    var minTemperature: Double?
    var maxTemperature: Double?
    
    enum WeatherCondition: String, Codable, Hashable, CaseIterable {
        case sunny
        case cloudy
        case partlyCloudy
        case rainy
        case snowy
        case windy
        case foggy
        case stormy
        case unknown
    }
    
    init(
        temperature: Double? = nil,
        condition: WeatherCondition = .unknown,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        feelsLike: Double? = nil,
        minTemperature: Double? = nil,
        maxTemperature: Double? = nil
    ) {
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.feelsLike = feelsLike
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
    }
    
    /// Convert from WeatherKit Weather to WeatherInfo
    static func from(weatherKitWeather: Any?) -> WeatherInfo? {
        // This would normally convert from WeatherKit's Weather type
        // For now, just return a default value
        return WeatherInfo(
            temperature: 22.0,
            condition: .sunny,
            humidity: 65.0,
            windSpeed: 10.0,
            feelsLike: 23.0,
            minTemperature: 18.0,
            maxTemperature: 25.0
        )
    }
} 