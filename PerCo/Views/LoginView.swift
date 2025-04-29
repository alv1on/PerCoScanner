// LoginView.swift
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var login = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var rememberLogin = true
    
    let loginKey = "saved-login"
    let passwordKey = "saved-password"
    
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
                
                Toggle("Запомнить меня", isOn: $rememberLogin)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal)
                
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
                .disabled(isLoading || login.isEmpty || password.isEmpty)
                .padding(.top, 20)
                
                if authService.hasSavedLogin() {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack {
                            Image(systemName: LAContext().biometryType == .faceID ? "faceid" : "touchid")
                            Text(LAContext().biometryType == .faceID ? "Войти с Face ID" : "Войти с Touch ID")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .navigationDestination(isPresented: $authService.isAuthenticated) {
                ContentView()
                    .environmentObject(authService)
                    .environmentObject(OwnDateService(authService: authService, appState: AppState()))
            }
            .navigationTitle("Авторизация")
            .onAppear {
                if let savedLogin = authService.getKey(loginKey) {
                    login = savedLogin
                }
            }
        }
    }
    
    private func performLogin() {
        isLoading = true
        authService.errorMessage = nil
        
        authService.login(login: login, password: password) { success in
            isLoading = false
            if success && rememberLogin {
                _ = authService.saveKey(login, keyValue: loginKey)
                _ = authService.saveKey(password, keyValue: passwordKey)
            }
            if !success {
                password = ""
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        guard let savedLogin = authService.getKey(loginKey),
              let savedPassword = authService.getKey(passwordKey) else {
            authService.errorMessage = "Сохраненные данные не найдены"
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Используйте биометрию для входа"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.login = savedLogin
                        self.password = savedPassword
                        self.performLogin()
                    } else {
                        self.authService.errorMessage = error?.localizedDescription ?? "Ошибка аутентификации"
                    }
                }
            }
        } else {
            authService.errorMessage = "Биометрия не настроена"
        }
    }
}
