import SwiftUI

class RedmineService: ObservableObject {
    private let authService: AuthService
    private let appState: AppState
    private let httpClient: HTTPClient
    @Published var searchResults: [RedmineIssue] = []
    
    init(authService: AuthService, appState: AppState, httpClient: HTTPClient) {
        self.authService = authService
        self.appState = appState
        self.httpClient = httpClient
    }
    
    func searchIssues(searchText: String, completion: @escaping (Result<[RedmineIssue], Error>) -> Void) {
        appState.isLoading = true
        
        guard let url = URL(string: "\(ApiConfig.Redmine.issues)?searchString=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
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
                        let issues = try JSONDecoder().decode([RedmineIssue].self, from: data)
                        self?.searchResults = issues
                        completion(.success(issues))
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
        issueId: String,
        hours: Int,
        minutes: Int,
        isRemoteWork: Bool,
        isOverTimeWork: Bool,
        comment: String,
        activityId: Int) {
        appState.isLoading = true
        
        let timeEntry = RedmineTimeEntry(
            activityId: activityId,
            issueId: issueId,
            hours: hours,
            minutes: minutes,
            comment: comment,
            isRemoteWork: isRemoteWork,
            isOverTimeWork: isOverTimeWork
        )
        
        guard let url = URL(string: ApiConfig.Redmine.createTimeEntry) else {
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
            appState.alertMessage = "Сессия истекла"
            authService.logout()
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
