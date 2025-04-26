import SwiftUI

@main
struct PerCoScanerApp: App {
    @StateObject var authService = AuthService.shared
        
    var body: some Scene {
            WindowGroup {
                if authService.isAuthenticated {
                    ContentView()
                        .transition(.opacity)
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
            .environmentObject(authService)
        }
}
