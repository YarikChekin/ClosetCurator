import Foundation
import CoreLocation

struct Weather {
    var temperature: Double?
    var condition: String?
    var humidity: Double?
    var windSpeed: Double?
    var location: String?
    var icon: String?
    var feelsLike: Double?
    var tempMin: Double?
    var tempMax: Double?
    var sunrise: Date?
    var sunset: Date?
    var forecast: [WeatherForecast]?
}

struct WeatherForecast {
    var date: Date
    var temperature: Double
    var condition: String
    var icon: String
}

class WeatherService: ObservableObject {
    @Published var currentWeather: Weather?
    private let locationManager = CLLocationManager()
    private let delegate = LocationDelegate()
    
    // OpenWeatherMap API key - replace with your own in a real app
    // Get a free key at: https://openweathermap.org/api
    private let apiKey = "INSERT_YOUR_OPENWEATHERMAP_API_KEY"
    
    init() {
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentWeather() async {
        // Try to get user's location
        if let location = await getCurrentLocation() {
            do {
                // Fetch the real weather data
                let weather = try await fetchWeatherData(latitude: location.coordinate.latitude, 
                                                        longitude: location.coordinate.longitude)
                
                // Update the published property on the main thread
                DispatchQueue.main.async {
                    self.currentWeather = weather
                }
            } catch {
                print("Error fetching weather: \(error)")
                // Fallback to mock data if there's an error
                provideMockWeather()
            }
        } else {
            // Fallback to mock data if location is unavailable
            provideMockWeather()
        }
    }
    
    func getWeatherForCity(city: String) async {
        do {
            let weather = try await fetchWeatherDataForCity(city: city)
            
            DispatchQueue.main.async {
                self.currentWeather = weather
            }
        } catch {
            print("Error fetching weather for \(city): \(error)")
            provideMockWeather()
        }
    }
    
    private func provideMockWeather() {
        DispatchQueue.main.async {
            self.currentWeather = Weather(
                temperature: 22.5,
                condition: "Partly Cloudy",
                humidity: 65.0,
                windSpeed: 10.0,
                location: "Current Location",
                icon: "04d",
                feelsLike: 23.0,
                tempMin: 20.0,
                tempMax: 25.0,
                forecast: [
                    WeatherForecast(date: Date().addingTimeInterval(86400),
                                 temperature: 23.0,
                                 condition: "Sunny",
                                 icon: "01d"),
                    WeatherForecast(date: Date().addingTimeInterval(172800),
                                 temperature: 21.0,
                                 condition: "Cloudy",
                                 icon: "03d"),
                    WeatherForecast(date: Date().addingTimeInterval(259200),
                                 temperature: 20.0,
                                 condition: "Rain",
                                 icon: "10d")
                ]
            )
        }
    }
    
    private func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            // First check if location services are enabled
            if CLLocationManager.locationServicesEnabled() {
                
                // Check if we already have a recent location
                if let location = locationManager.location {
                    continuation.resume(returning: location)
                    return
                }
                
                // Set up a one-time location callback
                delegate.locationUpdateHandler = { location in
                    continuation.resume(returning: location)
                }
                
                // Request location update
                locationManager.requestLocation()
                
                // If no location is received within 5 seconds, resume with nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if self.delegate.locationUpdateHandler != nil {
                        self.delegate.locationUpdateHandler = nil
                        continuation.resume(returning: nil)
                    }
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func fetchWeatherData(latitude: Double, longitude: Double) async throws -> Weather {
        // Current weather endpoint
        let currentURLString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(apiKey)"
        guard let currentURL = URL(string: currentURLString) else {
            throw WeatherError.invalidURL
        }
        
        // Forecast endpoint
        let forecastURLString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(apiKey)"
        guard let forecastURL = URL(string: forecastURLString) else {
            throw WeatherError.invalidURL
        }
        
        // Fetch current weather
        let (currentData, currentResponse) = try await URLSession.shared.data(from: currentURL)
        
        guard let currentHttpResponse = currentResponse as? HTTPURLResponse, currentHttpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }
        
        // Decode current weather
        let currentWeatherResponse = try JSONDecoder().decode(OpenWeatherCurrentResponse.self, from: currentData)
        var weather = currentWeatherResponse.toWeather()
        
        // Fetch forecast
        let (forecastData, forecastResponse) = try await URLSession.shared.data(from: forecastURL)
        
        guard let forecastHttpResponse = forecastResponse as? HTTPURLResponse, forecastHttpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }
        
        // Decode forecast
        let forecastResponse = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: forecastData)
        weather.forecast = forecastResponse.toForecast()
        
        return weather
    }
    
    private func fetchWeatherDataForCity(city: String) async throws -> Weather {
        // URL encode the city name
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw WeatherError.invalidURL
        }
        
        // Current weather endpoint
        let currentURLString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&units=metric&appid=\(apiKey)"
        guard let currentURL = URL(string: currentURLString) else {
            throw WeatherError.invalidURL
        }
        
        // Forecast endpoint
        let forecastURLString = "https://api.openweathermap.org/data/2.5/forecast?q=\(encodedCity)&units=metric&appid=\(apiKey)"
        guard let forecastURL = URL(string: forecastURLString) else {
            throw WeatherError.invalidURL
        }
        
        // Fetch current weather
        let (currentData, currentResponse) = try await URLSession.shared.data(from: currentURL)
        
        guard let currentHttpResponse = currentResponse as? HTTPURLResponse, currentHttpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }
        
        // Decode current weather
        let currentWeatherResponse = try JSONDecoder().decode(OpenWeatherCurrentResponse.self, from: currentData)
        var weather = currentWeatherResponse.toWeather()
        
        // Fetch forecast
        let (forecastData, forecastResponse) = try await URLSession.shared.data(from: forecastURL)
        
        guard let forecastHttpResponse = forecastResponse as? HTTPURLResponse, forecastHttpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }
        
        // Decode forecast
        let forecastResponse = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: forecastData)
        weather.forecast = forecastResponse.toForecast()
        
        return weather
    }
    
    enum WeatherError: Error {
        case invalidURL
        case invalidResponse
        case decodingError
        case locationError
    }
}

// MARK: - API Response Models

struct OpenWeatherCurrentResponse: Decodable {
    let main: Main
    let weather: [WeatherItem]
    let wind: Wind
    let name: String
    let sys: Sys
    
    struct Main: Decodable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
        let humidity: Double
    }
    
    struct WeatherItem: Decodable {
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Decodable {
        let speed: Double
    }
    
    struct Sys: Decodable {
        let sunrise: TimeInterval
        let sunset: TimeInterval
    }
    
    func toWeather() -> Weather {
        return Weather(
            temperature: main.temp,
            condition: weather.first?.main,
            humidity: main.humidity,
            windSpeed: wind.speed,
            location: name,
            icon: weather.first?.icon,
            feelsLike: main.feels_like,
            tempMin: main.temp_min,
            tempMax: main.temp_max,
            sunrise: Date(timeIntervalSince1970: sys.sunrise),
            sunset: Date(timeIntervalSince1970: sys.sunset),
            forecast: nil
        )
    }
}

struct OpenWeatherForecastResponse: Decodable {
    let list: [ForecastItem]
    
    struct ForecastItem: Decodable {
        let dt: TimeInterval
        let main: Main
        let weather: [WeatherItem]
        
        struct Main: Decodable {
            let temp: Double
        }
        
        struct WeatherItem: Decodable {
            let main: String
            let icon: String
        }
    }
    
    func toForecast() -> [WeatherForecast] {
        // Get daily forecasts (every 24 hours)
        let dailyForecasts = stride(from: 0, to: min(list.count, 40), by: 8).map { i in
            let item = list[i]
            return WeatherForecast(
                date: Date(timeIntervalSince1970: item.dt),
                temperature: item.main.temp,
                condition: item.weather.first?.main ?? "Unknown",
                icon: item.weather.first?.icon ?? "01d"
            )
        }
        
        return dailyForecasts
    }
}

// MARK: - Location Delegate

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var locationUpdateHandler: ((CLLocation?) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationUpdateHandler?(location)
            locationUpdateHandler = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        locationUpdateHandler?(nil)
        locationUpdateHandler = nil
    }
} 