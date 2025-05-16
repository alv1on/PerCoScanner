import SwiftUI

struct LogoutButton: View {
    @Binding var showLogoutAlert: Bool
    
    var body: some View {
        Button(action: { showLogoutAlert = true }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.gray, .blue)
        }
    }
}
