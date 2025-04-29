import Foundation
import JWTDecode
import LocalAuthentication

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var userName: String = ""
    
    private let tokenKey = "x-access-token"
    private let loginKey = "saved-login"
    private let passwordKey = "saved-password"
    
    private init() {
        checkToken()
    }
    
    // MARK: - Authentication State
    func checkToken() {
        if let token = getKey(tokenKey), isTokenValid(token) {
            isAuthenticated = true
            fetchUserInfo { _ in }
        } else {
            logout()
        }
    }
    
    func logout() {
        removeKey(tokenKey)
        isAuthenticated = false
        userName = ""
    }
    
    func isTokenValid(_ token: String) -> Bool {
        do {
            let jwt = try decode(jwt: token)
            return !jwt.expired
        } catch {
            return false
        }
    }
    
    func saveKey(_ value: String, keyValue: String) -> Bool {
        return KeychainService.save(key: keyValue, data: value)
    }
    
    func removeKey(_ value: String) {
        _ = KeychainService.delete(key: value)
    }
    func getKey(_ value: String) -> String? {
        return KeychainService.load(key: value)
    }
    
    func hasSavedLogin() -> Bool {
        return getKey(loginKey) != nil
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your account"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        self.errorMessage = error?.localizedDescription ?? "Ошибка аутентификации"
                        completion(false)
                    }
                }
            }
        } else {
            errorMessage = "Ошибка биометрии"
            completion(false)
        }
    }
    
    // MARK: - Network Operations
    func login(login: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: ApiConfig.Auth.login) else {
            errorMessage = "Некорректный URL"
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
                    self.processSuccessfulLogin(response: httpResponse, login: login, completion: completion)
                } else {
                    self.processFailedLogin(statusCode: httpResponse.statusCode, completion: completion)
                }
            }
        }.resume()
    }
    
    private func processSuccessfulLogin(response: HTTPURLResponse, login: String, completion: @escaping (Bool) -> Void) {
        if let setCookieHeader = response.allHeaderFields["Set-Cookie"] as? String,
           let range = setCookieHeader.range(of: "X-Access-Token=([^;]+)", options: .regularExpression) {
            let token = String(setCookieHeader[range].dropFirst("X-Access-Token=".count))
            
            if self.saveKey(token, keyValue: tokenKey) {
                _ = self.saveKey(login, keyValue: loginKey)
                self.isAuthenticated = true
                self.fetchUserInfo(completion: completion)
            } else {
                self.errorMessage = "Ошибка сохранение токена"
                completion(false)
            }
        } else {
            self.errorMessage = "Токен не найден"
            completion(false)
        }
    }
    
    private func processFailedLogin(statusCode: Int, completion: @escaping (Bool) -> Void) {
        errorMessage = statusCode == 401 ? "Неправильный логин или пароль" : "Ошибка сервера: \(statusCode)"
        completion(false)
    }
    
    func fetchUserInfo(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: ApiConfig.Account.userInfo),
              let token = getKey(tokenKey) else {
            errorMessage = "Ошибка авторизации"
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                self.processUserInfoResponse(data: data, response: response, completion: completion)
            }
        }.resume()
    }
    
    private func processUserInfoResponse(data: Data?, response: URLResponse?, completion: @escaping (Bool) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "Ошибка сервера"
            completion(false)
            return
        }
        
        switch httpResponse.statusCode {
        case 200:
            if let data = data, let name = self.extractUserName(from: data) {
                self.userName = name
                completion(true)
            } else {
                errorMessage = "Ошибка загрузки данных"
                completion(false)
            }
        case 401:
            logout()
            completion(false)
        default:
            errorMessage = "Ошибка сервера: \(httpResponse.statusCode)"
            completion(false)
        }
    }
    
    private func extractUserName(from data: Data) -> String? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json["name"] as? String
            }
        } catch {
            errorMessage = "Ошибка загрузки данных пользователя"
        }
        return nil
    }
}
