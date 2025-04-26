// AuthService.swift
import Foundation

class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var currentUser: String?
    
    private init() {} 
    
    func login(login: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: ApiConfig.Auth.login) else {
            errorMessage = "Неверный URL"
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["login": login, "password": password]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Ошибка сервера"
                    completion(false)
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.currentUser = login
                    self.isAuthenticated = true
                    completion(true)
                } else {
                    self.errorMessage = "Неверный логин или пароль"
                    completion(false)
                }
            }
        }.resume()
    }
    func logout() {
        self.isAuthenticated = false
        self.currentUser = nil
    }
}
