import Foundation
import SwiftUI

class OwnDateService: ObservableObject {
    private let authService: AuthService
    private let appState: AppState
    @Published var userEmails: [String] = []
    
    private let tokenKey = "x-access-token"
    
    init(authService: AuthService, appState: AppState) {
        self.authService = authService
        self.appState = appState
    }
    
    
    func fetchUserEmails(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: ApiConfig.User.userEmails),
              let token = authService.getKey(tokenKey) else {
            completion(.failure(NSError(domain: "Invalid URL or token", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let data = data else {
                    completion(.failure(NSError(domain: "Invalid response", code: 0)))
                    return
                }
                
                do {
                    let emails = try JSONDecoder().decode([String].self, from: data)
                    self.userEmails = emails
                    completion(.success(emails))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func createOwnDate(type: String, hours: Int, minutes: Int, isRemoteWork: Bool, selectedEmails: [String]) {
        appState.isLoading = true
        
        let ownDateRequest = OwnDate(
            type: type,
            hours: hours,
            minutes: minutes,
            isRemoteWork: isRemoteWork,
            emails: selectedEmails
        )
        
        guard let url = URL(string: ApiConfig.OwnDate.ownDate),
              let token = authService.getKey(tokenKey) else {
            appState.alertMessage = "Ошибка сервера"
            appState.showAlert = true
            appState.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(ownDateRequest)
        } catch {
            appState.alertMessage = "Ошибка формирования запроса"
            appState.showAlert = true
            appState.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.appState.isLoading = false
                
                if let error = error {
                    self.appState.alertMessage = "Ошибка: \(error.localizedDescription)"
                    self.appState.showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.appState.alertMessage = "Некорректный ответ сервера"
                    self.appState.showAlert = true
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    self.appState.alertMessage = "Событие успешно создано"
                } else if (httpResponse.statusCode == 401) {
                    self.appState.alertMessage = "Ошибка сервера"
                    self.authService.logout()
                }
                else{
                    self.appState.alertMessage = "Ошибка сервера: \(httpResponse.statusCode)"
                }
                self.appState.showAlert = true
            }
        }.resume()
    }
}
