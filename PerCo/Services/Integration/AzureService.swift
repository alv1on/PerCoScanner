import SwiftUI

class AzureService: ObservableObject {
    private let authService: AuthService
    private let appState: AppState
    private let httpClient: HTTPClient
    
    init(authService: AuthService, appState: AppState, httpClient: HTTPClient) {
        self.authService = authService
        self.appState = appState
        self.httpClient = httpClient
    }
    
    func searchIssues(searchText: String, projectScope: String, completion: @escaping (Result<[WorkItem], Error>) -> Void) {
            appState.isLoading = true
            
            // Создаем URL с параметрами запроса
            var urlComponents = URLComponents(string: ApiConfig.Azure.issues)!
            urlComponents.queryItems = [
                URLQueryItem(name: "searchString", value: searchText),
                URLQueryItem(name: "projectScope", value: projectScope)
            ]
            
            guard let url = urlComponents.url else {
                completion(.failure(NetworkError.invalidURL))
                appState.isLoading = false
                return
            }
            
            httpClient.request(url) { [weak self] result in
                DispatchQueue.main.async {
                    self?.appState.isLoading = false
                    
                    switch result {
                    case .success((let data, _)):
                        do {
                            let response = try JSONDecoder().decode([WorkItem].self, from: data)
                            completion(.success(response))
                        } catch {
                            self?.handleError(message: "Ошибка обработки данных: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        self?.handleNetworkError(error)
                        completion(.failure(error))
                    }
                }
            }
        }
    
    func createTimeEntry(
        workItemId: Int,
        hours: Int,
        minutes: Int,
        isRemoteWork: Bool,
        isOverTimeWork: Bool,
        comment: String,
        workType: String,
        projectScope: String
    ) {
        appState.isLoading = true
        
        let timeEntry = TimeEntry(
            workItemId: workItemId,
            hours: hours,
            minutes: minutes,
            comment: comment,
            workType: workType,
            isRemoteWork: isRemoteWork,
            isOverTimeWork: isOverTimeWork,
            projectScope: projectScope
        )
        
        guard let url = URL(string: ApiConfig.Azure.createTimeEntry) else {
            handleError(message: "Ошибка сервера")
            return
        }
        
        httpClient.request(url, method: "POST", body: timeEntry) { [weak self] result in
            DispatchQueue.main.async {
                self?.appState.isLoading = false
                
                switch result {
                case .success:
                    self?.appState.alertMessage = "Учет времени успешно сохранен"
                case .failure(let error):
                    self?.handleNetworkError(error)
                }
                self?.appState.showAlert = true
            }
        }
    }
    
    private func handleNetworkError(_ error: Error) {
        switch error {
        case NetworkError.unauthorized:
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
