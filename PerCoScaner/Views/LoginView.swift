// LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var login = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("perco-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .padding(.bottom, 30)
                
                TextField("Логин", text: $login)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: performLogin) {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }
                        Text("Войти")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || login.isEmpty || password.lengthOfBytes(using: .utf8) < 8)
                .padding(.top, 20)
            }
            .padding()
            .navigationDestination(isPresented: $authService.isAuthenticated) {
                ContentView()
            }
            .navigationTitle("Авторизация")
        }
    }
    
    private func performLogin() {
        isLoading = true
        authService.errorMessage = nil
        
        authService.login(login: login, password: password) { success in
            isLoading = false
            if !success {
                password = ""
            }
        }
    }
}
