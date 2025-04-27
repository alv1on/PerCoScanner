import SwiftUI

class AppState: ObservableObject {
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var isLoading = false
}
