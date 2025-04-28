// AuthService.swift
import Foundation
import JWTDecode

class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let tokenKey = "x-access-token"
    private let userDefaults = UserDefaults.standard
    
    private init() {
           checkToken()
       }
       
       func checkToken() {
           if let token = getStoredToken(), isTokenValid(token) {
               isAuthenticated = true
           } else {
               logout()
           }
       }
    
    private func saveToken(_ token: String) {
        userDefaults.set(token, forKey: tokenKey)
    }
    
    private func removeToken() {
        userDefaults.removeObject(forKey: tokenKey)
    }
    
    func getStoredToken() -> String? {
        return userDefaults.string(forKey: tokenKey)
    }
    
    
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
                    if let setCookieHeader = httpResponse.allHeaderFields["Set-Cookie"] as? String,
                       let range = setCookieHeader.range(of: "X-Access-Token=([^;]+)", options: .regularExpression) {
                        let token = String(setCookieHeader[range].dropFirst("X-Access-Token=".count))
                        self.saveToken(token)
                    }
                    
                    self.isAuthenticated = true
                    completion(true)
                } else {
                    self.errorMessage = "Неверный логин или пароль"
                    completion(false)
                }
            }
        }.resume()
    }
    
    func isTokenValid(_ token: String) -> Bool {
            do {
                let jwt = try decode(jwt: token)
                return !jwt.expired
            } catch {
                return false
            }
        }
    
    func logout() {
        removeToken()
        self.isAuthenticated = false
    }
}
