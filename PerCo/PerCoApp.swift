import SwiftUI

@main
struct PerCoApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var appState = AppState()
    @StateObject private var notificationService = NotificationService()
    @State private var showSplash = true
    
    private var httpClient: HTTPClient {
        HTTPClient(
            tokenProvider: { [weak authService] in
                authService?.getKey("x-access-token")
            },
            unauthorizedHandler: { authService.handleUnauthorized() }
        )
    }
    
    private var ownDateService: OwnDateService {
        OwnDateService(
            authService: authService,
            appState: appState,
            httpClient: httpClient
        )
    }
    
    private var azureService: AzureService {
        AzureService(
            authService: authService,
            appState: appState,
            httpClient: httpClient
        )
    }
    
    private var attendanceService: AttendanceService {
        AttendanceService(
            authService: authService,
            appState: appState,
            httpClient: httpClient
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    if authService.isAuthenticated {
                        ContentView()
                            .environmentObject(notificationService)
                            .environmentObject(authService)
                            .environmentObject(appState)
                            .environmentObject(ownDateService)
                            .environmentObject(azureService)
                            .environmentObject(attendanceService)
                    } else {
                        LoginView()
                            .environmentObject(authService)
                    }
                }
            }
            .onAppear {
                // Задержка для демонстрации splash screen (можно заменить на реальную загрузку данных)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
        }
    }
}
