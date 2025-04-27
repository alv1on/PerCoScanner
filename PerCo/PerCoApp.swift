import SwiftUI

@main
struct PerCoApp: App {
    @StateObject var authService = AuthService.shared
    @StateObject var appState = AppState()
    @StateObject var ownDateService: OwnDateService
    
    init() {
        let auth = AuthService.shared
        let state = AppState()
        _authService = StateObject(wrappedValue: auth)
        _appState = StateObject(wrappedValue: state)
        _ownDateService = StateObject(wrappedValue: OwnDateService(authService: auth, appState: state))
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
                    .environmentObject(appState)
                    .environmentObject(ownDateService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
