import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var ownDateService: OwnDateService
    @EnvironmentObject var appState: AppState
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    @State private var showLogoutAlert = false
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var isShowingTimePicker = false
    @State private var isRemoteWork = false
    @State private var timePickerType: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Приветственный заголовок
                    VStack {
                        Text("Добро пожаловать")
                            .font(.title)
                    }
                    .padding(.top, 20)
                    
                    // Плитки с кнопками
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Кнопка "Начать рабочий день"
                        ActionTileView(
                            icon: "calendar.badge.plus",
                            label: "Начать день",
                            action: {
                                timePickerType = "EnterManual"
                                selectedHours = 10
                                selectedMinutes = 0
                                isRemoteWork = false
                                isShowingTimePicker = true
                            },
                            isLoading: appState.isLoading
                        )
                        // Кнопка "QR сканер"
                        ActionTileView(
                            icon: "qrcode.viewfinder",
                            label: "Сканировать",
                            action: { isShowingScanner = true }
                        )
                        // Кнопка "Закончить день"
                        ActionTileView(
                            icon: "calendar.badge.checkmark",
                            label: "Закончить день",
                            action: {
                                timePickerType = "ExitManual"
                                selectedHours = 18
                                selectedMinutes = 30
                                isRemoteWork = false 
                                isShowingTimePicker = true
                            },
                            isLoading: appState.isLoading
                        )
                        // Кнопка "Настройки"
                        ActionTileView(
                            icon: "gearshape",
                            label: "Настройки",
                            action: { /* Добавьте действие */ }
                        )
                    }
                    .padding(.horizontal)
                    
                    // Отсканированный код (появляется ниже плиток)
                    if let code = scannedCode {
                        VStack(spacing: 10) {
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
                        }
                        .padding()
                        .transition(.slide)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("PerCo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showLogoutAlert = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
                Button("Выйти", role: .destructive) { authService.logout() }
                Button("Отмена", role: .cancel) {}
            }
            .alert(appState.alertMessage, isPresented: $appState.showAlert) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $isShowingScanner) {
                QRScannerView(
                    onQRCodeScanned: { code in
                        scannedCode = code
                        isShowingScanner = false
                    },
                    onDismiss: { isShowingScanner = false }
                )
                .edgesIgnoringSafeArea(.all)
            }.sheet(isPresented: $isShowingTimePicker) {
                TimePickerView(
                    hours: $selectedHours,
                    minutes: $selectedMinutes,
                    isRemoteWork: $isRemoteWork,
                    onCancel: { isShowingTimePicker = false },
                    onConfirm: {
                        if let type = timePickerType {
                            ownDateService.createOwnDate(
                                type: type,
                                hours: selectedHours,
                                minutes: selectedMinutes,
                                isRemoteWork: isRemoteWork
                            )
                        }
                        isShowingTimePicker = false
                    }
                )
            }
        }
    }
}
