import SwiftUI
import WeatherKit
import CoreLocation

struct WeatherView: View {
    @EnvironmentObject private var weatherService: WeatherService
    @StateObject private var locationManager = LocationManager()
    @State private var selectedDay = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Weather
                    if let current = weatherService.currentWeather?.currentWeather {
                        CurrentWeatherView(weather: current)
                            .padding(.horizontal)
                    }
                    
                    // Hourly Forecast
                    VStack(alignment: .leading) {
                        Text("Hourly Forecast")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(weatherService.hourlyForecast, id: \.date) { hour in
                                    HourlyForecastView(hour: hour)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Daily Forecast
                    VStack(alignment: .leading) {
                        Text("7-Day Forecast")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(weatherService.dailyForecast, id: \.date) { day in
                            DailyForecastView(day: day)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Outfit Recommendations
                    VStack(alignment: .leading) {
                        Text("Recommended Outfits")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        if let temp = weatherService.getCurrentTemperature() {
                            Text("Based on \(Int(temp))° weather")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        // TODO: Add outfit recommendations based on weather
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Weather")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            if let location = locationManager.location {
                                await weatherService.fetchWeather(for: location)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                if let location = locationManager.location {
                    await weatherService.fetchWeather(for: location)
                }
            }
        }
    }
}

struct CurrentWeatherView: View {
    let weather: CurrentWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(weather.temperature.value))°")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text(weather.condition.description)
                        .font(.subheadline)
                }
                
                Spacer()
                
                Image(systemName: weather.symbolName)
                    .font(.system(size: 48))
            }
            
            HStack {
                WeatherDetailView(title: "Feels Like", value: "\(Int(weather.apparentTemperature.value))°")
                Spacer()
                WeatherDetailView(title: "Humidity", value: "\(Int(weather.humidity * 100))%")
                Spacer()
                WeatherDetailView(title: "Wind", value: "\(Int(weather.wind.speed.value)) mph")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct HourlyForecastView: View {
    let hour: HourWeather
    
    var body: some View {
        VStack {
            Text(hourFormatter.string(from: hour.date))
                .font(.caption)
            
            Image(systemName: hour.symbolName)
                .font(.title2)
            
            Text("\(Int(hour.temperature.value))°")
                .font(.callout)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
    
    private var hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()
}

struct DailyForecastView: View {
    let day: DayWeather
    
    var body: some View {
        HStack {
            Text(dayFormatter.string(from: day.date))
                .frame(width: 100, alignment: .leading)
            
            Image(systemName: day.symbolName)
                .frame(width: 30)
            
            Spacer()
            
            Text("\(Int(day.lowTemperature.value))°")
                .foregroundColor(.secondary)
            
            Text("\(Int(day.highTemperature.value))°")
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
    
    private var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

struct WeatherDetailView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.callout)
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
} 