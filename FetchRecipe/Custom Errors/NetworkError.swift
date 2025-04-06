//
//  NetworkError.swift
//  FetchRecipe
//
//  Created by Rishi Garg on 4/6/25.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidData
    /// HTTP response status codes
    case invalidResponse    // Default
    case badRequest         // 400
    case unauthorized       // 401
    case forbidden          // 403
    case notFound           // 404
    case serverError        // 500
    static func error(for statusCode: Int) -> NetworkError {
        switch statusCode {
        case 400:
            return .badRequest
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 500...599:
            return .serverError
        default:
            return .invalidResponse
        }
    }
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidData:
            return "The data received is invalid."
        case .invalidResponse:
            return "The response from the server is invalid."
        case .badRequest:
            return "Bad request. Please try again."
        case .unauthorized:
            return "Unauthorized access. Please check your credentials."
        case .forbidden:
            return "Access forbidden. You do not have permission to access this resource."
        case .notFound:
            return "Resource not found. Please check the URL."
        case .serverError:
            return "Server error. Please try again later."
        }
    }
}
