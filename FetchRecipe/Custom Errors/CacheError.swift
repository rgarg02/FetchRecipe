//
//  CacheError.swift
//  FetchRecipe
//
//  Created by Rishi Garg on 4/6/25.
//

import Foundation

enum CacheError: Error, LocalizedError {
    case directoryNotFound
    case writeFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .directoryNotFound: return "Cache directory could not be found or created."
        case .writeFailed(let underlyingError): return "Failed to write data to cache: \(underlyingError.localizedDescription)"
        }
    }
}
