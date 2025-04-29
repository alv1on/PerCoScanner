
enum NetworkError: Error {
    case invalidResponse
    case unauthorized
    case serverError(statusCode: Int)
    case encodingError
    case invalidURL
    case noData
}
