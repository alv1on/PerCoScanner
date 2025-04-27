import Foundation
import SwiftUI

class OwnDateService: ObservableObject {
    private let authService: AuthService
    private let appState: AppState
    
    init(authService: AuthService, appState: AppState) {
        self.authService = authService
        self.appState = appState
    }
    
    func createOwnDate(type: String) {
        appState.isLoading = true
        
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        let requestBody: [String: Any] = [
            "dateTimes": [currentDate],
            "type": type,
            "hours": 10,
            "minutes": 0,
            "comment": "",
            "isRemoteWork": false,
            "emails": []
        ]
        
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
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
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
                } else {
                    self.appState.alertMessage = "Ошибка сервера: \(httpResponse.statusCode)"
                }
                self.appState.showAlert = true
            }
        }.resume()
    }
}
