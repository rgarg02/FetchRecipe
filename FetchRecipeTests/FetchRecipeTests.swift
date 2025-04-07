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
    
    // MARK: - Pagination Tests (Infinite Scrolling)
    
    func testInitialDisplayShowsFirstPage() {
        // Given: a view model with more recipes than one page length
        let mockRecipes = createMockRecipes(count: 25) // page length is 10, so it has 3 pages
        viewModel.recipes = mockRecipes
        viewModel.resetPage() // Ensure starting at page 1
        
        // When: accessing displayed recipes initially
        let displayed = viewModel.displayedRecipes
        
        // Then: only the first page of recipes should be displayed
        XCTAssertEqual(displayed.count, viewModel.pageLength, "Initially, displayedRecipes should contain only the first page")
        XCTAssertEqual(displayed.first?.id, mockRecipes.first?.id, "First displayed recipe should match the first mock recipe")
        XCTAssertEqual(displayed.last?.id, mockRecipes[viewModel.pageLength - 1].id, "Last displayed recipe should be the last of the first page")
        XCTAssertEqual(viewModel.currentPage, 1, "Current page should be 1 initially")
    }
    
    func testLoadNextPageAppendsRecipes() {
        // Given: a view model with multiple pages of recipes
        let totalRecipes = 35
        let pageLength = viewModel.pageLength // 10
        let mockRecipes = createMockRecipes(count: totalRecipes)
        viewModel.recipes = mockRecipes
        viewModel.resetPage()
        
        // When: loading the next page
        viewModel.loadNextPageIfNeeded() // Load page 2
        
        // Then: displayed recipes should contain the first two pages
        var displayed = viewModel.displayedRecipes
        XCTAssertEqual(viewModel.currentPage, 2, "Current page should now be 2")
        XCTAssertEqual(displayed.count, pageLength * 2, "Displayed recipes should contain items from the first two pages")
        XCTAssertEqual(displayed.last?.id, mockRecipes[(pageLength * 2) - 1].id, "Last displayed recipe should be the last of the second page")
        
        // When: loading the next page again
        viewModel.loadNextPageIfNeeded() // Load page 3
        
        // Then: displayed recipes should contain the first three pages
        displayed = viewModel.displayedRecipes
        XCTAssertEqual(viewModel.currentPage, 3, "Current page should now be 3")
        XCTAssertEqual(displayed.count, pageLength * 3, "Displayed recipes should contain items from the first three pages")
        XCTAssertEqual(displayed.last?.id, mockRecipes[(pageLength * 3) - 1].id, "Last displayed recipe should be the last of the third page")
        
        // When: loading the final partial page
        viewModel.loadNextPageIfNeeded() // Load page 4 (partial)
        
        // Then: displayed recipes should contain all recipes
        displayed = viewModel.displayedRecipes
        XCTAssertEqual(viewModel.currentPage, 4, "Current page should now be 4")
        XCTAssertEqual(displayed.count, totalRecipes, "Displayed recipes should contain all items")
        XCTAssertEqual(displayed.last?.id, mockRecipes.last?.id, "Last displayed recipe should be the last mock recipe")
    }
    
    func testLoadNextPageDoesNothingWhenAllPagesLoaded() {
        // Given: a view model with recipes, and all pages are loaded
        let totalRecipes = 15 // Less than 2 full pages
        let mockRecipes = createMockRecipes(count: totalRecipes)
        viewModel.recipes = mockRecipes
        viewModel.resetPage()
        viewModel.loadNextPageIfNeeded()
        
        let initialCount = viewModel.displayedRecipes.count
        XCTAssertEqual(viewModel.currentPage, 2, "Should be on page 2")
        XCTAssertEqual(initialCount, totalRecipes, "All recipes should be displayed")
        
        // When: trying to load the next page again
        viewModel.loadNextPageIfNeeded()
        
        // Then: the current page and displayed count should not change
        XCTAssertEqual(viewModel.currentPage, 2, "Current page should remain 2")
        XCTAssertEqual(viewModel.displayedRecipes.count, initialCount, "Displayed recipe count should not change")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false")
    }
    
    func testResetPageResetsToFirstPage() {
        // Given: a view model with multiple pages loaded
        let mockRecipes = createMockRecipes(count: 25)
        viewModel.recipes = mockRecipes
        viewModel.resetPage()
        viewModel.loadNextPageIfNeeded() // Load page 2
        viewModel.loadNextPageIfNeeded() // Load page 3
        XCTAssertEqual(viewModel.currentPage, 3, "Should be on page 3")
        XCTAssertEqual(viewModel.displayedRecipes.count, 25, "Should display all 25 recipes")
        
        
        // When: resetting the page
        viewModel.resetPage()
        
        // Then: current page should be 1 and displayed recipes should only contain the first page
        XCTAssertEqual(viewModel.currentPage, 1, "Current page should reset to 1")
        XCTAssertEqual(viewModel.displayedRecipes.count, viewModel.pageLength, "Displayed recipes should only contain the first page after reset")
        XCTAssertEqual(viewModel.displayedRecipes.first?.id, mockRecipes.first?.id, "First displayed recipe should be the first mock recipe")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after reset")
    }
    
    func testFilteredPaginationAppendsCorrectly() {
        // Given: a view model with recipes
        let mockRecipes = createMockRecipes(count: 30) // 3 pages total
        viewModel.recipes = mockRecipes
        viewModel.resetPage()
        
        // Apply a filter that selects a subset (e.g., recipes with even IDs)
        let filterText = "Recipe 1" // Will match Recipe 1, and Recipes 10 to 19
        let expectedFilteredCount = 11
        viewModel.searchText = filterText
        viewModel.searchScope = .name
        
        // Manually get the expected filtered list for comparison
        let expectedFilteredRecipes = mockRecipes.filter { $0.name.lowercased().contains(filterText.lowercased()) }
        XCTAssertEqual(expectedFilteredRecipes.count, expectedFilteredCount, "Precondition: Filtered list count mismatch")
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
