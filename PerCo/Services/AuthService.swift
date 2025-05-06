import Foundation
import JWTDecode
import LocalAuthentication

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var userName: String = ""
    @Published var employeeId: String = ""
    
    let tokenKey = "x-access-token"
    let refreshTokenKey = "x-refresh-token"
    let loginKey = "saved-login"
    let passwordKey = "saved-password"
    
    private lazy var httpClient: HTTPClient = {
        HTTPClient(tokenProvider: { [weak self] in
            self?.getKey(self?.tokenKey ?? "")
        }, unauthorizedHandler: { [weak self] in
            self?.handleUnauthorized()
        })
    }()
    
    init() {
        checkToken()
    }
    // MARK: - Authentication State
    func checkToken() {
        if let token = getKey(tokenKey), isTokenValid(token) {
            isAuthenticated = true
            fetchUserInfo { _ in }
        } else {
            handleUnauthorized()
        }
    }
    
    func logout() {
        removeKey(tokenKey)
        removeKey(refreshTokenKey)
        isAuthenticated = false
        userName = ""
        employeeId = ""
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
            let reason = "Авторизуйтесь для доступа к аккаунта"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        self.errorMessage = error?.localizedDescription ?? "Ошибка авторизации"
                        completion(false)
                    }
                }
            }
        } else {
            errorMessage = "Ошибка биометрии"
            completion(false)
        }
    }
    
    func login(login: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: ApiConfig.Auth.login) else {
            errorMessage = "Некорректный URL"
            completion(false)
            return
        }
        
        let body = ["login": login, "password": password]
        
        httpClient.request(url, method: "POST", body: body) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let (data, response)):
                    self.processLoginResponse(data: data, response: response, login: login, completion: completion)
                case .failure(let error):
                    self.handleLoginError(error)
                    completion(false)
                }
            }
        }
    }
    
    func handleUnauthorized() {
        guard let refreshToken = getKey(refreshTokenKey) else {
            logout()
            return
        }
        
        refreshAccessToken(refreshToken: refreshToken) { [weak self] success in
            if !success {
                self?.logout()
            }
        }
    }
    
    
    private func refreshAccessToken(refreshToken: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: ApiConfig.Auth.refresh) else {
            errorMessage = "Некорректный URL"
            completion(false)
            return
        }
        
        let body = ["refreshToken": refreshToken]
        
        httpClient.request(url, method: "POST", body: body) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false)
                    return
                }
                
                switch result {
                case .success(let (data, response)):
                    self.processTokenResponse(data: data, response: response, completion: completion)
                case .failure(let error):
                    self.errorMessage = "Ошибка обновления токена: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    private func processTokenResponse(data: Data, response: HTTPURLResponse, completion: @escaping (Bool) -> Void) {
        if let setCookieHeader = response.allHeaderFields["Set-Cookie"] as? String {
            var newAccessToken: String?
            var newRefreshToken: String?
            
            // Извлекаем access token
            if let range = setCookieHeader.range(of: "X-Access-Token=([^;]+)", options: .regularExpression) {
                newAccessToken = String(setCookieHeader[range].dropFirst("X-Access-Token=".count))
            }
            
            // Извлекаем refresh token
            if let range = setCookieHeader.range(of: "X-Refresh-Token=([^;]+)", options: .regularExpression) {
                newRefreshToken = String(setCookieHeader[range].dropFirst("X-Refresh-Token=".count))
            }
            
            guard let accessToken = newAccessToken, let refreshToken = newRefreshToken else {
                errorMessage = "Токены не найдены в ответе"
                completion(false)
                return
            }
            
            if self.saveKey(accessToken, keyValue: tokenKey) &&
               self.saveKey(refreshToken, keyValue: refreshTokenKey) {
                completion(true)
            } else {
                errorMessage = "Ошибка сохранения токенов"
                completion(false)
            }
        } else {
            errorMessage = "Не удалось получить токены из заголовков"
            completion(false)
        }
    }
    
    private func processLoginResponse(data: Data, response: HTTPURLResponse, login: String, completion: @escaping (Bool) -> Void) {
        if let setCookieHeader = response.allHeaderFields["Set-Cookie"] as? String {
            var accessToken: String?
            var refreshToken: String?
            
            // Извлекаем access token
            if let range = setCookieHeader.range(of: "X-Access-Token=([^;]+)", options: .regularExpression) {
                accessToken = String(setCookieHeader[range].dropFirst("X-Access-Token=".count))
            }
            
            // Извлекаем refresh token
            if let range = setCookieHeader.range(of: "X-Refresh-Token=([^;]+)", options: .regularExpression) {
                refreshToken = String(setCookieHeader[range].dropFirst("X-Refresh-Token=".count))
            }
            
            guard let accessToken = accessToken, let refreshToken = refreshToken else {
                self.errorMessage = "Токены не найдены"
                completion(false)
                return
            }
            
            if self.saveKey(accessToken, keyValue: tokenKey) &&
               self.saveKey(refreshToken, keyValue: refreshTokenKey) {
                _ = self.saveKey(login, keyValue: loginKey)
                self.isAuthenticated = true
                self.fetchUserInfo(completion: completion)
            } else {
                self.errorMessage = "Ошибка сохранения токенов"
                completion(false)
            }
        } else {
            self.errorMessage = "Токены не найдены в заголовках"
            completion(false)
        }
    }
    
    private func handleLoginError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                errorMessage = "Неправильный логин или пароль"
            case .serverError(let code):
                errorMessage = "Ошибка сервера: \(code)"
            default:
                errorMessage = "Ошибка сети"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchUserInfo(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: ApiConfig.Account.userInfo) else {
            errorMessage = "Некорректный URL"
            completion(false)
            return
        }
        
        httpClient.request(url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false)
                    return
                }
                
                switch result {
                case .success((let data, _)):
                    self.processUserInfo(data: data) { success in
                        if success {
                            // После успешного получения userInfo вызываем getEmployee
                            self.getEmployee(completion: completion)
                        } else {
                            completion(false)
                        }
                    }
                case .failure(let error):
                    self.handleUserInfoError(error)
                    completion(false)
                    self.handleUnauthorized()
                }
            }
        }
    }
    
    private func processUserInfo(data: Data, completion: @escaping (Bool) -> Void) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["name"] as? String {
                self.userName = name
                completion(true)
            } else {
                errorMessage = "Ошибка загрузки данных пользователя"
                completion(false)
            }
        } catch {
            errorMessage = "Ошибка обработки данных"
            completion(false)
        }
    }

    
    func getEmployee(completion: @escaping (Bool) -> Void) {
        guard var urlComponents = URLComponents(string: ApiConfig.Attendance.employee) else {
            DispatchQueue.main.async {
                self.errorMessage = "Некорректный URL"
                completion(false)
            }
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "onlyMe", value: "true")
        ]
        
        guard let url = urlComponents.url else {
            DispatchQueue.main.async {
                self.errorMessage = "Ошибка формирования URL"
                completion(false)
            }
            return
        }
        
        httpClient.request(url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false)
                    return
                }
                
                switch result {
                case .success((let data, _)):
                    self.processEmployee(data: data, completion: completion)
                case .failure(let error):
                    self.handleUserInfoError(error)
                    completion(false)
                }
            }
        }
    }
    
    private func processEmployee(data: Data, completion: @escaping (Bool) -> Void) {
        do {
            // Парсим массив словарей
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                // Берем первый элемент массива
                if let firstEmployee = jsonArray.first,
                   let employeeId = firstEmployee["externalEmployeeId"] as? String {
                    self.employeeId = employeeId
                    completion(true)
                } else {
                    errorMessage = "Не удалось получить данные сотрудника из массива"
                    completion(false)
                }
            }
        } catch {
            errorMessage = "Ошибка обработки данных: \(error.localizedDescription)"
            completion(false)
        }
    }
    
    private func handleUserInfoError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                errorMessage = "Сессия истекла"
                handleUnauthorized()
            case .serverError(let code):
                errorMessage = "Ошибка сервера: \(code)"
            default:
                errorMessage = "Ошибка приложения"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
