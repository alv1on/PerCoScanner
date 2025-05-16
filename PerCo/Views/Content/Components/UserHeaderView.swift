import SwiftUI

struct UserHeaderView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            if !authService.userName.isEmpty {
                Text(authService.userName)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(Date().formatted(date: .abbreviated, time: .omitted))
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.top, 2)
        }
        .padding(.top, 20)
    }
}
