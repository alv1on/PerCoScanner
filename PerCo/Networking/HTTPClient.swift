import Foundation

class HTTPClient {
    private let tokenProvider: () -> String?
    private let unauthorizedHandler: (() -> Void)?
    
    init(tokenProvider: @escaping () -> String? = { nil }, unauthorizedHandler: (() -> Void)? = nil) {
        self.tokenProvider = tokenProvider
        self.unauthorizedHandler = unauthorizedHandler
    }
    
    func request(
        _ url: URL,
        method: String = "GET",
        body: Encodable? = nil,
        completion: @escaping (Result<(data: Data, response: HTTPURLResponse), Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self.unauthorizedHandler?()
                    completion(.failure(NetworkError.unauthorized))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode)))
                    return
                }
                
                guard let responseData = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                completion(.success((responseData, httpResponse)))
            }
        }.resume()
    }
}
