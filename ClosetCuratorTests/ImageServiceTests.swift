import XCTest
@testable import ClosetCurator

final class ImageServiceTests: XCTestCase {
    var service: ImageService!
    var testItem: ClothingItem!
    
    override func setUp() {
        super.setUp()
        service = ImageService.shared
        testItem = ClothingItem(
            name: "Test Item",
            category: .tops,
            color: "Blue"
        )
    }
    
    func testImageProcessing() async throws {
        // Create a test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Convert to data
        guard let imageData = testImage.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }
        
        // Process the image
        let processedData = try await service.processImage(imageData)
        
        // Verify the processed data is not empty
        XCTAssertFalse(processedData.isEmpty)
        
        // Verify we can create an image from the processed data
        let processedImage = UIImage(data: processedData)
        XCTAssertNotNil(processedImage)
    }
    
    func testImageStorage() async throws {
        // Create a test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Convert to data
        guard let imageData = testImage.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create image data")
            return
        }
        
        // Save the image
        let imageURL = try await service.saveImage(imageData, for: testItem)
        
        // Verify the file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL.path))
        
        // Verify we can read the image back
        let savedData = try Data(contentsOf: imageURL)
        let savedImage = UIImage(data: savedData)
        XCTAssertNotNil(savedImage)
        
        // Clean up
        try await service.removeImage(for: testItem)
        XCTAssertFalse(FileManager.default.fileExists(atPath: imageURL.path))
    }
    
    func testInvalidImageData() async {
        // Test with invalid image data
        let invalidData = Data([0, 1, 2, 3])
        
        do {
            _ = try await service.processImage(invalidData)
            XCTFail("Expected error for invalid image data")
        } catch ImageError.invalidImageData {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
} 