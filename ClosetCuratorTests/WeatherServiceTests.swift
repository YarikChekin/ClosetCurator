import XCTest
@testable import ClosetCurator
import WeatherKit

final class WeatherServiceTests: XCTestCase {
    var service: WeatherService!
    
    override func setUp() {
        super.setUp()
        service = WeatherService()
    }
    
    func testTemperatureBasedTags() {
        // Create mock weather conditions
        let coldWeather = createMockWeather(temperature: 5)
        let coolWeather = createMockWeather(temperature: 15)
        let warmWeather = createMockWeather(temperature: 22)
        let hotWeather = createMockWeather(temperature: 30)
        
        // Test cold weather tags
        let coldTags = service.getWeatherTags(for: coldWeather)
        XCTAssertTrue(coldTags.contains(.cold))
        
        // Test cool weather tags
        let coolTags = service.getWeatherTags(for: coolWeather)
        XCTAssertTrue(coolTags.contains(.cool))
        
        // Test warm weather tags
        let warmTags = service.getWeatherTags(for: warmWeather)
        XCTAssertTrue(warmTags.contains(.warm))
        
        // Test hot weather tags
        let hotTags = service.getWeatherTags(for: hotWeather)
        XCTAssertTrue(hotTags.contains(.hot))
    }
    
    func testWeatherConditionTags() {
        // Test rainy weather
        let rainyWeather = createMockWeather(temperature: 20, condition: .rain)
        let rainyTags = service.getWeatherTags(for: rainyWeather)
        XCTAssertTrue(rainyTags.contains(.rainy))
        
        // Test snowy weather
        let snowyWeather = createMockWeather(temperature: 0, condition: .snow)
        let snowyTags = service.getWeatherTags(for: snowyWeather)
        XCTAssertTrue(snowyTags.contains(.snowy))
    }
    
    // Helper function to create mock weather
    private func createMockWeather(temperature: Double, condition: WeatherCondition = .clear) -> Weather {
        // Since we can't directly create a Weather instance, we'll create a mock
        // that conforms to the necessary protocol
        class MockWeather: Weather {
            var currentWeather: CurrentWeather
            var dailyForecast: Forecast<DayWeather>
            var hourlyForecast: Forecast<HourWeather>
            
            init(temperature: Double, condition: WeatherCondition) {
                self.currentWeather = MockCurrentWeather(temperature: temperature, condition: condition)
                self.dailyForecast = Forecast(forecast: [])
                self.hourlyForecast = Forecast(forecast: [])
            }
        }
        
        class MockCurrentWeather: CurrentWeather {
            var temperature: Measurement<UnitTemperature>
            var condition: WeatherCondition
            
            init(temperature: Double, condition: WeatherCondition) {
                self.temperature = Measurement(value: temperature, unit: .celsius)
                self.condition = condition
            }
        }
        
        return MockWeather(temperature: temperature, condition: condition)
    }
} 