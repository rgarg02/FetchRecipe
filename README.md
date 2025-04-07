# Fetch Mobile Take Home Project - Recipe App

### Summary

This iOS application displays recipes fetched from a provided API endpoint. The main screen (`RecipeListView`) presents a scrollable and searchable list of recipes, showing each recipe's name, cuisine type, and a small photo. Users can pull-to-refresh the list. Tapping a recipe navigates to a detail screen (`RecipeDetailView`) which shows a larger photo (if available), name, cuisine, and links to the source website and/or YouTube video. The app utilizes modern SwiftUI for the user interface and Swift Concurrency for handling asynchronous operations. It includes a custom disk-based image caching mechanism.

**Features:**

* **Recipe List & Detail:**

<img src="https://github.com/user-attachments/assets/f118b92d-aa6e-473a-bc56-1eaabf32465e" alt="Recipe List" width="200"> <img src="https://github.com/user-attachments/assets/b3175d48-0195-42b3-bd09-ca095ace7c45" alt="Recipe Detail" width="200">

* **Search & Filtering:** Includes search functionality with scopes (All, Cuisine, Name).
<img src="https://github.com/user-attachments/assets/9dff0be8-f378-4cb6-a1c0-8f1aca541c37" alt="Search Scopes and Searchable" width="200">

* **Pull to Refresh:** Allows users to refresh the recipe list easily.
<img src="https://github.com/user-attachments/assets/d6ed604c-146f-4589-8121-ae4b7e5c45a7" alt="Pull to Refresh" width="200">

* **Navigation Transition:** Uses a zoom transition effect when navigating to the detail view (requires iOS 18+).
<img src="https://github.com/user-attachments/assets/fcec4458-f762-4ec6-bdea-94ca4b7f1422" alt="Navigation Zoom Transition (iOS 18+)" width="200">

* **Links to Source and Video:** Uses a zoom transition effect when navigating to the detail view (requires iOS 18+).
<img src="https://github.com/user-attachments/assets/f9c769be-9ff3-44c2-bb5e-6db9b1cb667d" alt="Links to Source and Youtube Video" width="200">

* **Infinite Scrolling:** Automatically loads more recipes as the user scrolls to the bottom of the list using pagination.

* **Custom Image Caching:** Efficiently loads and caches images to disk.

* **DocC Documentation:** Includes DocC documentation for functions, providing better understanding of the code.   
### Focus Areas

1.  **Swift Concurrency (`async/await`):** Ensuring all network calls (fetching recipes, fetching images) and related asynchronous tasks were implemented using `async/await` for modern, efficient concurrency handling while maintaining a smooth experience for the user.
2.  **Custom Image Caching:** Building an image caching system from scratch using `FileManager` to store images on disk. This involved creating a dedicated cache directory, handling cache hits/misses, saving downloaded images, and implementing a basic cache eviction strategy (clearing the cache when size or item count limits are exceeded) without relying on `URLSession`'s built-in caching or `URLCache`. Filenames for cached items are derived from Base64 encoding of the image URL to ensure filesystem compatibility. However this could be improved if I used CryptoKit library to use SHA256 encryption.
3.  **SwiftUI Implementation:** Building the entire UI using SwiftUI, including `NavigationStack` for navigation, `LazyVStack` for efficient list display, `.searchable` and `.searchScopes` modifiers for searching/filtering, and `.refreshable` for pull-to-refresh functionality. `AsyncImage` was used in the detail view for simplicity, while the list view uses the custom caching mechanism. The navigation link also uses the new Navigation Transition modifier released in iOS 18. Proper handling of the available iOS version was placed so that users with versions < iOS 18 can still use the app.
5.  **Unit Testing:** Implementing unit tests (`WorkspaceRecipeTests.swift`) to cover essential logic in the `RecipeViewModel`, including network fetching success/failure, cache operations (save, load, clear), and pagination logic.

### Time Spent

* **Total:** 4 hours
* **Allocation:**
    * Project Setup & Model Creation: 0.5 hours
    * Networking Layer (API calls): 0.5 hours
    * Custom Image Caching Implementation: 1 hour
    * SwiftUI View Implementation (List, Detail, Row): 0.5 hours
    * Unit Testing: 1 hours
    * Debugging & Refinement: 0.5 hours

### Trade-offs and Decisions

* **Cache Eviction:** The current cache eviction strategy is basic: it completely clears the entire cache directory if either the total size or item count limit is exceeded. A more sophisticated cache eviction policy, like Last Recently Used (LRU) could have been used for better performance. However I thought it would be beyond the scope of this exercise. If I were to implement LRU, I could have done so by using the fileCreationDate property from the fileManager.
* **Error Handling:** Error handling primarily relies on displaying alerts to the user (`showAlert` property in ViewModels/Views). More specific UI feedback (e.g., inline error messages, placeholder images with error icons in the list view for individual image load failures) could be implemented but was kept simple. The app handles the malformed JSON data by catching the decoding error and presenting an alert popup to the user. The empty JSON data is handled by showing a ContentUnavailableView.
* **Image Loading in Detail View:** `AsyncImage` is used in `RecipeDetailView` for simplicity. While it uses the shared `URLSession` cache by default (which the requirements discouraged for the *custom* cache implementation), integrating the custom cache here would add complexity. The requirement focused on custom caching for *repeated* requests (like list thumbnails), which is implemented.
* **Pagination:** Since the API does not allow for pagination, it is handled by the view model by slicing the array stored in the memory. This simulates the pagination behavior however not necessary since all the recipes are loading in the memory anyways.
  
### Weakest Part of the Project

* **Cache Eviction:** Currently the cache is entirely emptied when it reaches the size or count limit. This could be improved significantly by implementing LRU policy.

### Additional Information

* **Minimum Target:** The project implicitly targets iOS 17+ due to the use of `@Observable` macro. I could have easily added support for iOS 16+ by using the ObservableObject instead.
* **Models:** Codable models (`Recipe`, `RecipeList`) were used for straightforward JSON parsing. `CodingKeys` were used to map JSON snake_case keys to Swift camelCase properties.
