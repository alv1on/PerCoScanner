import SwiftUI

@main
struct PerCoScanerApp: App {
    @StateObject var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authService)
    }
}
