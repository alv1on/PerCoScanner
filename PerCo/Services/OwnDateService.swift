import Foundation
import SwiftUI

class OwnDateService: ObservableObject {
    private let authService: AuthService
    private let appState: AppState
    
    init(authService: AuthService, appState: AppState) {
        self.authService = authService
        self.appState = appState
    }
    
    func createOwnDate(type: String, hours: Int, minutes: Int, isRemoteWork: Bool) {
        appState.isLoading = true
        
        let ownDateRequest = OwnDate(
            type: type,
            hours: hours,
            minutes: minutes,
            isRemoteWork: isRemoteWork
        )

        guard let url = URL(string: ApiConfig.OwnDate.ownDate),
              let token = authService.getStoredToken() else {
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
                    self.authService.logout()
                    self.appState.alertMessage = "Ошибка авторизации"
                }
                else{
                    self.appState.alertMessage = "Ошибка сервера: \(httpResponse.statusCode)"
                }
                self.appState.showAlert = true
            }
        }.resume()
    }
}
