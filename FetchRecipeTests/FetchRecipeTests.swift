import XCTest
@testable import FetchRecipe // Assuming the module name is FetchRecipe

class RecipeViewModelTests: XCTestCase {
    
    var viewModel: RecipeViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = RecipeViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Pagination Tests
    
    func testFetchRecipesWithValidPage() {
        // Given: a view model with a known set of recipes
        let mockRecipes = createMockRecipes(count: 25)
        viewModel.recipes = mockRecipes
        
        // When: fetching different pages
        let page1 = viewModel.fetchRecipes(page: 1)
        let page2 = viewModel.fetchRecipes(page: 2)
        let page3 = viewModel.fetchRecipes(page: 3)
        
        // Then: each page should contain the correct number of recipes
        XCTAssertEqual(page1.count, 10, "Page 1 should have 10 recipes")
        XCTAssertEqual(page2.count, 10, "Page 2 should have 10 recipes")
        XCTAssertEqual(page3.count, 5, "Page 3 should have 5 recipes")
        
        // And the first recipe of each page should be the expected one
        XCTAssertEqual(page1.first?.id, mockRecipes[0].id, "First recipe on page 1 should be the first mock recipe")
        XCTAssertEqual(page2.first?.id, mockRecipes[10].id, "First recipe on page 2 should be the 11th mock recipe")
        XCTAssertEqual(page3.first?.id, mockRecipes[20].id, "First recipe on page 3 should be the 21st mock recipe")
    }
    
    func testFetchRecipesWithInvalidPage() {
        // Given: a view model with a few recipes
        viewModel.recipes = createMockRecipes(count: 5)
        
        // When: fetching with invalid page numbers
        let negativePageResult = viewModel.fetchRecipes(page: -1)
        let zeroPageResult = viewModel.fetchRecipes(page: 0)
        let tooHighPageResult = viewModel.fetchRecipes(page: 3) // Only enough for 1 page
        
        // Then: all should return empty arrays
        XCTAssertTrue(negativePageResult.isEmpty, "Negative page number should return empty array")
        XCTAssertTrue(zeroPageResult.isEmpty, "Zero page number should return empty array")
        XCTAssertTrue(tooHighPageResult.isEmpty, "Page number beyond available data should return empty array")
    }
    
    // MARK: - Cache Tests
    
    func testCacheOperations() {
        // Given: test data to cache
        let testImageUrl = "https://example.com/test-image.jpg"
        let testData = "test data".data(using: .utf8)!
        
        // When: saving to cache
        try? viewModel.saveToCache(data: testData, forKey: testImageUrl)
        let cachedData = viewModel.loadFromCache(forKey: testImageUrl)
        
        // Then: data should be retrievable from cache
        XCTAssertNotNil(cachedData, "Data should be successfully cached")
        XCTAssertEqual(cachedData, testData, "Cached data should match original data")
        
        // When: clearing cache
        viewModel.clearImageCacheAndInstantiate()
        
        // Then: data should no longer be in cache
        XCTAssertNil(viewModel.loadFromCache(forKey: testImageUrl), "Cache should be cleared")
    }
    
    // MARK: - Network Tests
    
    func testFetchAllRecipesSuccess() async throws {
        // Given: a mock view model that will succeed
        let mockViewModel = MockRecipeViewModel(shouldSucceed: true)
        
        // When: fetching all recipes
        try await mockViewModel.fetchAllRecipes()
        
        // Then: recipes should be populated
        XCTAssertFalse(mockViewModel.recipes.isEmpty, "Recipes should be populated after successful fetch")
        XCTAssertFalse(mockViewModel.showAlert, "Alert should not be shown on success")
    }
    
    func testFetchAllRecipesFailure() async {
        // Given: a mock view model that will fail
        let mockViewModel = MockRecipeViewModel(shouldSucceed: false)
        
        // When: fetching all recipes
        do {
            try await mockViewModel.fetchAllRecipes()
            XCTFail("fetchAllRecipes should throw error")
        } catch {
            XCTAssertTrue(error is NetworkError, "Error should be a NetworkError")
        }
    }
    
    func testFetchImageSuccess() async throws {
        // Given: a mock view model that will succeed
        let mockViewModel = MockRecipeViewModel(shouldSucceed: true)
        let testImageUrl = "https://example.com/valid-image.jpg"
        
        // When: fetching an image
        let imageData = try await mockViewModel.fetchImageData(urlString: testImageUrl)
        
        // Then: should receive data and cache it
        XCTAssertFalse(imageData.isEmpty, "Image data should not be empty")
        
        // Check if it was cached
        let cachedData = mockViewModel.loadFromCache(forKey: testImageUrl)
        XCTAssertNotNil(cachedData, "Image should be cached after fetching")
    }
    
    func testFetchImageWithCacheHit() async throws {
        // Given: a mock view model with pre-cached data
        let mockViewModel = MockRecipeViewModel(shouldSucceed: true)
        let testImageUrl = "https://example.com/cached-image.jpg"
        let cachedData = "cached data".data(using: .utf8)!
        
        // Pre-cache the image
        try mockViewModel.saveToCache(data: cachedData, forKey: testImageUrl)
        
        // When: fetching the same image
        let fetchedData = try await mockViewModel.fetchImageData(urlString: testImageUrl)
        
        // Then: should get data from cache
        XCTAssertEqual(fetchedData, cachedData, "Should fetch data from cache")
    }
    
    func testFetchImageInvalidURL() async {
        // Given: a mock view model and invalid URL
        let mockViewModel = MockRecipeViewModel(shouldSucceed: true)
        let invalidImageUrl = "" // Empty URL
        
        // When: fetching with invalid URL
        do {
            _ = try await mockViewModel.fetchImageData(urlString: invalidImageUrl)
            XCTFail("fetchImageData should throw for invalid URL")
        } catch {
            // Then: should throw invalidURL error
            XCTAssertEqual(error as? NetworkError, NetworkError.invalidURL, "Error should be invalidURL")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInitErrorPropagation() async {
        // Given: a view model that will fail during init
        let expectation = XCTestExpectation(description: "Error shown")
        let mockViewModel = FailingInitViewModel()
        
        // Allow time for async init to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then: alert should be shown with correct error
            XCTAssertTrue(mockViewModel.showAlert, "Alert should be shown on error")
            XCTAssertEqual(mockViewModel.error, NetworkError.invalidResponse)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockRecipes(count: Int) -> [Recipe] {
        let cuisines = ["Malaysian", "British", "American", "Canadian", "Tunisian"]
        var recipes: [Recipe] = []
        for i in 0..<count {
            let recipe =  Recipe(cuisine: cuisines.randomElement()!, name: "Recipe \(i)", photoUrlLarge: "https://test.com/recipe\(i)/large.jpg", photoUrlSmall: "https://test.com/recipe\(i)/small.jpg", id: "\(i)", sourceUrl: "https://test.com/recipe\(i)", youtubeUrl: "https://youtube.com/watch?v=\(i)")
            recipes.append(recipe)
        }
        return recipes
    }
}

// MARK: - Mock Classes for Testing

class MockRecipeViewModel: RecipeViewModel {
    let shouldSucceed: Bool
    
    init(shouldSucceed: Bool) {
        self.shouldSucceed = shouldSucceed
        super.init()
    }
    
    override func fetchAllRecipes() async throws {
        if shouldSucceed {
            await MainActor.run {
                self.recipes = createMockRecipes(count: 20)
            }
        } else {
            throw NetworkError.invalidResponse
        }
    }
    
    override func fetchImageData(urlString: String) async throws -> Data {
        if urlString.isEmpty {
            throw NetworkError.invalidURL
        }
        
        // Check cache first as the real implementation would
        if let cachedData = loadFromCache(forKey: urlString) {
            return cachedData
        }
        
        if shouldSucceed {
            let mockData = "mock image data".data(using: .utf8)!
            try saveToCache(data: mockData, forKey: urlString)
            return mockData
        } else {
            throw NetworkError.invalidResponse
        }
    }
    
    private func createMockRecipes(count: Int) -> [Recipe] {
        let cuisines = ["Malaysian", "British", "American", "Canadian", "Tunisian"]
        var recipes: [Recipe] = []
        for i in 0..<count {
            let recipe =  Recipe(cuisine: cuisines.randomElement()!, name: "Recipe \(i)", photoUrlLarge: "https://test.com/recipe\(i)/large.jpg", photoUrlSmall: "https://test.com/recipe\(i)/small.jpg", id: "\(i)", sourceUrl: "https://test.com/recipe\(i)", youtubeUrl: "https://youtube.com/watch?v=\(i)")
            recipes.append(recipe)
        }
        return recipes
    }
}

class FailingInitViewModel: RecipeViewModel {
    override func fetchAllRecipes() async throws {
        throw NetworkError.invalidResponse
    }
}
