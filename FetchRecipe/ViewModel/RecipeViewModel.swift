//
//  RecipeViewModel.swift
//  FetchRecipe
//
//  Created by Rishi Garg on 4/6/25.
//  Modified to include custom image caching.
//

import Observation
import Foundation

@Observable
class RecipeViewModel {
    var recipes: [Recipe] = []
    var showAlert = false
    var error: NetworkError = .invalidResponse
    var searchText = ""
    var searchScope: searchScope = .all
    let apiURL = "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json"
    let pageLength = 10
    var currentPage = 1
    var isLoading = false
    // Cache Manager Properties
    private let fileManager = FileManager.default
    private var cacheDirectory: URL?
    private var cacheSize: Int64 = 0
    private var cacheCount: Int = 0
    private let cacheLimit: Int64 = 1024 * 1024 * 5 // 2 MB
    private let cacheCountLimit: Int = 100 // Limit to 50 images
    init() {
        clearImageCacheAndInstantiate()
        Task {
            do {
                try await fetchAllRecipes()
            } catch {
                // Ensure error handling captures the specific error
                if let networkError = error as? NetworkError {
                    self.error = networkError
                } else {
                    self.error = .badRequest
                }
                self.showAlert = true
            }
        }
    }
    
    // MARK: - Recipe Fetching
    
    /// Returns the full list of recipes filtered by searchText and searchScope.
    private var filteredRecipes: [Recipe] {
        // (Logic unchanged from previous version)
        if searchText.isEmpty {
            return recipes
        } else {
            let lowercasedSearchText = searchText.lowercased()
            switch searchScope {
            case .all:
                return recipes.filter { $0.name.lowercased().contains(lowercasedSearchText) || $0.cuisine.lowercased().contains(lowercasedSearchText) }
            case .cuisine:
                return recipes.filter { $0.cuisine.lowercased().contains(lowercasedSearchText) }
            case .name:
                return recipes.filter { $0.name.lowercased().contains(lowercasedSearchText) }
            }
        }
    }
    
    /// Returns the calculated total number of pages based on the filtered results.
    var totalFilteredPages: Int {
        let totalItems = filteredRecipes.count
        return (totalItems + pageLength - 1) / pageLength
    }
    
    /// Returns the recipes for 1 to current page
    var displayedRecipes: [Recipe] {
        let filtered = filteredRecipes
        let itemsToDisplayCount = currentPage * pageLength
        let endIndex = min(itemsToDisplayCount, filtered.count)
        
        guard endIndex >= 0 else { return [] }
        
        return Array(filtered[0..<endIndex])
    }
    
    // MARK: - Pagination Methods
    
    /// Resets the current page to 1 and clears loading state.
    func resetPage() {
        currentPage = 1
        isLoading = false
    }
    
    /// Increments the current page if not already loading and if more pages exist.
    func loadNextPageIfNeeded() {
        guard !isLoading, currentPage < totalFilteredPages else {
            return
        }
        
        self.isLoading = true
        
        self.currentPage += 1
        self.isLoading = false
        
    }
    func cuisineTypes() -> [String] {
        let cuisines = Set(recipes.map { $0.cuisine })
        return Array(cuisines).sorted()
    }
    
    /// Fetch all recipes from the API
    func fetchAllRecipes() async throws {
        guard let url = URL(string: apiURL) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.error(for: httpResponse.statusCode)
        }
        do {
            let decoder = JSONDecoder()
            let recipeList = try decoder.decode(RecipeList.self, from: data)
            // Updating the recipes property on the main actor
            await MainActor.run {
                self.recipes = []
                self.recipes = recipeList.recipes
            }
        } catch {
            throw NetworkError.invalidData
        }
    }
    
    // MARK: - Image Fetching and Caching
    
    /// Fetches image data, checking disk cache first.
    /// - Parameter urlString: The URL string of the image to fetch.
    /// - Returns: The image data.
    /// - Throws: NetworkError or CacheError.
    func fetchImageData(urlString: String) async throws -> Data {
        // 1. Check Cache
        if let cachedData = loadFromCache(forKey: urlString) {
            print("Cache hit for: \(urlString)")
            return cachedData
        }
        
        // 2. Cache Miss: Fetch from Network
        print("Cache miss for: \(urlString)")
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.error(for: httpResponse.statusCode)
        }
        
        // 3. Save to Cache
        try saveToCache(data: data, forKey: urlString)
        // print("Saved to cache: \(urlString)")
        
        return data
    }
    
    // MARK: - Custom Cache Management
    
    /// Sets up the dedicated cache directory.
    private func setupCacheDirectory() {
        guard let cachesUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Error: Could not find caches directory.")
            return
        }
        let imageCacheUrl = cachesUrl.appendingPathComponent("ImageCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: imageCacheUrl.path) {
            do {
                try fileManager.createDirectory(at: imageCacheUrl, withIntermediateDirectories: true, attributes: nil)
                self.cacheDirectory = imageCacheUrl
                print("Cache directory created at: \(imageCacheUrl.path)")
            } catch {
                print("Error creating cache directory: \(error)")
                self.cacheDirectory = nil
            }
        } else {
            self.cacheDirectory = imageCacheUrl
            // print("Cache directory already exists at: \(imageCacheUrl.path)")
        }
    }
    
    
    /// Clears the image cache directory, resets counters, and ensures directory exists.
    func clearImageCacheAndInstantiate() {
        guard let cachesUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Error: Could not find caches directory to clear cache.")
            return
        }
        let imageCacheUrl = cachesUrl.appendingPathComponent("ImageCache", isDirectory: true)
        
        if fileManager.fileExists(atPath: imageCacheUrl.path) {
            do {
                try fileManager.removeItem(at: imageCacheUrl)
                print("Successfully cleared image cache directory at: \(imageCacheUrl.path)")
            } catch {
                print("Error removing existing cache directory \(imageCacheUrl.path): \(error)")
                // Attempt to continue, setupCacheDirectory might fix it
            }
        } else {
            // print("Cache directory did not exist, no need to clear.")
        }
        
        // Reset counters
        cacheSize = 0
        cacheCount = 0
        
        // Ensure the directory exists *after* attempting to clear
        // Reset cacheDirectory property so setup runs again
        self.cacheDirectory = nil
        setupCacheDirectory()
    }
    
    /// Generates a safe filename using Base64 encoding from the URL string.
    /// - Parameter key: The URL string used as the cache key.
    /// - Returns: A filesystem-safe Base64 encoded filename string.
    private func cacheFilename(forKey key: String) -> String {
        // Convert the URL string (key) to Data
        guard let data = key.data(using: .utf8) else {
            return key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "invalid_url_key_\(UUID().uuidString)"
        }
        return data.base64EncodedString()
    }
    
    /// Gets the file path for the cache directory.
    /// - Parameter key: The URL string used as the cache key.
    /// - Returns: The file URL for the cache file.
    private func cacheFilePath(forKey key: String) -> URL? {
        guard let cacheDirectory = self.cacheDirectory else {
            print("Error: Cache directory not available.")
            return nil
        }
        // Generate filename using Base64 encoding
        let filename = cacheFilename(forKey: key)
        let safeFilename = filename.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent(safeFilename)
    }
    
    /// Saves data to the disk cache.
    /// - Parameters:
    ///   - data: The image data to save.
    ///   - key: The URL string used as the cache key.
    /// - Throws: A CacheError if saving fails.
    func saveToCache(data: Data, forKey key: String) throws {
        guard let filePath = cacheFilePath(forKey: key) else {
            throw CacheError.directoryNotFound
        }
        do {
            try data.write(to: filePath)
            cacheSize += Int64(data.count)
            cacheCount += 1
            checkCacheSizeAndCount()
        } catch {
            print("Error writing to cache file \(filePath.lastPathComponent): \(error)")
            throw CacheError.writeFailed(error)
        }
    }
    
    private func checkCacheSizeAndCount() {
        if cacheSize > cacheLimit || cacheCount > cacheCountLimit {
            clearImageCacheAndInstantiate()
        }
    }
    
    /// Loads data from the disk cache.
    /// - Parameter key: The URL string used as the cache key.
    /// - Returns: The cached data, or nil if not found or an error occurs.
    func loadFromCache(forKey key: String) -> Data? {
        guard let filePath = cacheFilePath(forKey: key) else {
            return nil
        }
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            return nil // Cache miss
        }
        
        do {
            let data = try Data(contentsOf: filePath)
            return data
        } catch {
            print("Error reading from cache file \(filePath.lastPathComponent): \(error)")
            return nil
        }
    }
}
