import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack {
                    Text("Добро пожаловать")
                        .font(.title)
                    Text(authService.currentUser ?? "")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // Основной контент
                if let code = scannedCode {
                    VStack(spacing: 15) {
                        Text("Отсканированный код:")
                            .font(.headline)
                        
                        Text(code)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = code
                                } label: {
                                    Label("Копировать", systemImage: "doc.on.doc")
                                }
                            }
                        
                        Button(action: { isShowingScanner = true }) {
                            Label("Сканировать снова", systemImage: "qrcode.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Готов к сканированию")
                            .font(.title2.bold())
                        
                        Button(action: { isShowingScanner = true }) {
                            Label("Начать сканирование", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("PerCo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showLogoutAlert = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
                Button("Выйти", role: .destructive) {
                    authService.logout()
                }
                Button("Отмена", role: .cancel) {}
            }
            .sheet(isPresented: $isShowingScanner) {
                QRScannerView(
                    onQRCodeScanned: { code in
                        scannedCode = code
                        isShowingScanner = false
                    },
                    onDismiss: {
                        isShowingScanner = false
                    }
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}
