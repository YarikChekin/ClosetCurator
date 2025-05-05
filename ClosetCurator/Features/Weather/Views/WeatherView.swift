import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var isLoading = false
    @State private var selectedCity = ""
    @State private var isShowingCitySearch = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Weather
                    if let weather = weatherService.currentWeather {
                        CurrentWeatherView(weather: weather)
                            .padding(.horizontal)
                    } else {
                        ProgressView()
                            .padding()
                    }
                    
                    // Forecast
                    if let forecast = weatherService.currentWeather?.forecast, !forecast.isEmpty {
                        VStack(alignment: .leading) {
                            Text("5-Day Forecast")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 15) {
                                    ForEach(forecast, id: \.date) { day in
                                        DailyForecastView(forecast: day)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Outfit Recommendations Section
                    if let temp = weatherService.currentWeather?.temperature {
                        VStack(alignment: .leading) {
                            Text("Outfit Recommendations")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            Text("Based on \(Int(temp))° \(weatherService.currentWeather?.condition ?? "weather")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            // Weather-based clothing suggestions
                            WeatherClothingSuggestions(weather: weatherService.currentWeather!)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Weather Details
                    if let weather = weatherService.currentWeather {
                        WeatherDetailsView(weather: weather)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Weather")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isLoading = true
                            await weatherService.getCurrentWeather()
                            isLoading = false
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingCitySearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .task {
                isLoading = true
                await weatherService.getCurrentWeather()
                isLoading = false
            }
            .sheet(isPresented: $isShowingCitySearch) {
                CitySearchView(onSearch: { city in
                    Task {
                        isLoading = true
                        await weatherService.getWeatherForCity(city: city)
                        isLoading = false
                        isShowingCitySearch = false
                    }
                })
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        }
                }
            }
        }
    }
}

struct CurrentWeatherView: View {
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(weather.temperature ?? 0))°")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text(weather.condition ?? "Unknown")
                        .font(.subheadline)
                    
                    Text(weather.location ?? "Unknown Location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                WeatherIconView(iconCode: weather.icon ?? "01d")
                    .frame(width: 60, height: 60)
            }
            
            HStack {
                WeatherDetailView(title: "Feels Like", value: "\(Int(weather.feelsLike ?? 0))°")
                Spacer()
                WeatherDetailView(title: "Humidity", value: "\(Int(weather.humidity ?? 0))%")
                Spacer()
                WeatherDetailView(title: "Wind", value: "\(Int(weather.windSpeed ?? 0)) m/s")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct DailyForecastView: View {
    let forecast: WeatherForecast
    
    var body: some View {
        VStack {
            Text(formatDate(forecast.date))
                .font(.caption)
            
            WeatherIconView(iconCode: forecast.icon)
                .frame(width: 40, height: 40)
            
            Text("\(Int(forecast.temperature))°")
                .font(.callout)
            
            Text(forecast.condition)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct WeatherClothingSuggestions: View {
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let temp = weather.temperature {
                if temp < 5 {
                    ClothingTipRow(
                        title: "Very Cold",
                        suggestion: "Heavy coat, layers, hat, gloves, and scarf",
                        icon: "snow"
                    )
                } else if temp < 12 {
                    ClothingTipRow(
                        title: "Cold",
                        suggestion: "Coat, sweater, jeans, and boots",
                        icon: "thermometer.low"
                    )
                } else if temp < 18 {
                    ClothingTipRow(
                        title: "Cool",
                        suggestion: "Light jacket, long sleeves, and pants",
                        icon: "cloud"
                    )
                } else if temp < 24 {
                    ClothingTipRow(
                        title: "Mild",
                        suggestion: "Light layers, t-shirt with light jacket, pants or skirt",
                        icon: "sun.min"
                    )
                } else if temp < 30 {
                    ClothingTipRow(
                        title: "Warm",
                        suggestion: "T-shirt, shorts/skirt, and light fabrics",
                        icon: "sun.max"
                    )
                } else {
                    ClothingTipRow(
                        title: "Hot",
                        suggestion: "Light, breathable clothing, shorts, and sun protection",
                        icon: "thermometer.high"
                    )
                }
                
                if let condition = weather.condition?.lowercased() {
                    if condition.contains("rain") {
                        ClothingTipRow(
                            title: "Rainy",
                            suggestion: "Bring umbrella, wear water-resistant shoes",
                            icon: "cloud.rain"
                        )
                    } else if condition.contains("snow") {
                        ClothingTipRow(
                            title: "Snowy",
                            suggestion: "Waterproof boots, warm socks, and gloves",
                            icon: "cloud.snow"
                        )
                    } else if condition.contains("wind") {
                        ClothingTipRow(
                            title: "Windy",
                            suggestion: "Windbreaker or jacket, secure hat",
                            icon: "wind"
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

struct ClothingTipRow: View {
    let title: String
    let suggestion: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WeatherDetailsView: View {
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weather Details")
                .font(.headline)
                .padding(.bottom, 4)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                if let min = weather.tempMin, let max = weather.tempMax {
                    GridRow {
                        Text("Min Temp:")
                            .foregroundColor(.secondary)
                        Text("\(Int(min))°")
                    }
                    
                    GridRow {
                        Text("Max Temp:")
                            .foregroundColor(.secondary)
                        Text("\(Int(max))°")
                    }
                }
                
                if let sunrise = weather.sunrise, let sunset = weather.sunset {
                    GridRow {
                        Text("Sunrise:")
                            .foregroundColor(.secondary)
                        Text(formatTime(sunrise))
                    }
                    
                    GridRow {
                        Text("Sunset:")
                            .foregroundColor(.secondary)
                        Text(formatTime(sunset))
                    }
                }
                
                if let humidity = weather.humidity {
                    GridRow {
                        Text("Humidity:")
                            .foregroundColor(.secondary)
                        Text("\(Int(humidity))%")
                    }
                }
                
                if let windSpeed = weather.windSpeed {
                    GridRow {
                        Text("Wind:")
                            .foregroundColor(.secondary)
                        Text("\(Int(windSpeed)) m/s")
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
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

struct WeatherIconView: View {
    let iconCode: String
    
    var body: some View {
        AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png")) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "cloud.fill")
                    .resizable()
                    .scaledToFit()
            @unknown default:
                Image(systemName: "cloud.fill")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

struct CitySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cityName = ""
    let onSearch: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Enter city name", text: $cityName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.words)
                
                Button("Search") {
                    if !cityName.isEmpty {
                        onSearch(cityName)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Search City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WeatherView()
} 