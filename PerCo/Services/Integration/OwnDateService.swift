import Foundation
import SwiftUI

class OwnDateService: ObservableObject {
    private let authService: AuthService
    private let appState: AppState
    private let httpClient: HTTPClient
    @Published var userEmails: [String] = []
    
    init(authService: AuthService, appState: AppState, httpClient : HTTPClient) {
        self.authService = authService
        self.appState = appState
        self.httpClient = httpClient
    }
    
    
    func fetchUserEmails(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: ApiConfig.User.userEmails) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        httpClient.request(url) { result in
            switch result {
            case .success((let data, _)):
                do {
                    let emails = try JSONDecoder().decode([String].self, from: data)
                    self.userEmails = emails
                    completion(.success(emails))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
        
        guard let url = URL(string: ApiConfig.OwnDate.ownDate) else {
            handleError(message: "Ошибка сервера")
            return
        }
        
        httpClient.request(url, method: "POST", body: ownDateRequest) { result in
            DispatchQueue.main.async {
                self.appState.isLoading = false
                
                switch result {
                case .success:
                    self.appState.alertMessage = "Событие успешно создано"
                case .failure(let error):
                    self.handleNetworkError(error)
                }
                self.appState.showAlert = true
            }
        }
    }
    private func handleNetworkError(_ error: Error) {
        switch error {
        case NetworkError.unauthorized:
            appState.alertMessage = "Сессия истекла"
            authService.handleUnauthorized()
        default:
            appState.alertMessage = "Ошибка: \(error.localizedDescription)"
        }
    }
    
    private func handleError(message: String) {
        appState.isLoading = false
        appState.alertMessage = message
        appState.showAlert = true
    }
}
