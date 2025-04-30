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
    @State private var isShowingOwnTypeList = false
    @State private var isRemoteWork = false
    @State private var timePickerType: String?
    @State private var selectedEmails: [String] = []
    @State private var selectedEventType = "OwnExpenses"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Приветственный заголовок
                    VStack {
                        Text("Добро пожаловать")
                            .font(.title)
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
                    
                    // Плитки с кнопками
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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
                        
                        ActionTileView(
                            icon: "qrcode.viewfinder",
                            label: "Сканировать",
                            action: { isShowingScanner = true }
                        )
                        
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
                        ActionTileView(
                            icon: "calendar.badge.exclamationmark",
                            label: "Создать событие",
                            action: {
                                isShowingOwnTypeList = true
                            },
                            isLoading: appState.isLoading
                        )
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .padding()
            }
            .refreshable {
                await refreshData()
            }
            .navigationTitle("PerCo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showLogoutAlert = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue)
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
            }
            .sheet(isPresented: $isShowingTimePicker) {
                TimePickerView(
                    hours: $selectedHours,
                    minutes: $selectedMinutes,
                    isRemoteWork: $isRemoteWork,
                    selectedEmails: $selectedEmails,
                    onCancel: { isShowingTimePicker = false },
                    onConfirm: {
                        if let type = timePickerType {
                            ownDateService.createOwnDate(
                                type: type,
                                hours: selectedHours,
                                minutes: selectedMinutes,
                                isRemoteWork: isRemoteWork,
                                selectedEmails: selectedEmails
                            )
                        }
                        isShowingTimePicker = false
                    }
                )
            }
            .sheet(isPresented: $isShowingOwnTypeList) {
                EventTypePickerView(
                    selectedEventType: $selectedEventType,
                    onCancel: {
                        isShowingOwnTypeList = false
                    },
                    onConfirm: {
                        ownDateService.createOwnDate(
                            type: selectedEventType,
                            hours: selectedHours,
                            minutes: selectedMinutes,
                            isRemoteWork: isRemoteWork,
                            selectedEmails: selectedEmails
                        )
                        isShowingOwnTypeList = false
                    }
                )
                .environmentObject(ownDateService)
            }
            .onAppear {
                if authService.isAuthenticated {
                    authService.fetchUserInfo { _ in }
                }
            }
        }
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            authService.fetchUserInfo { _ in
                continuation.resume()
            }
        }
    }
}
