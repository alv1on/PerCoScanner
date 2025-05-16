import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var ownDateService: OwnDateService
    @EnvironmentObject var azureService: AzureService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var attendanceService: AttendanceService

    @State private var progressState = WorkDayProgressState()
    @State private var modalState = ModalSheetsState()
    @State private var formState = FormInputState()

    @State private var showLogoutAlert = false
    @State private var isScanButtonAnimating = false
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Шапка с именем пользователя и датой
                    UserHeaderView()
                        .environmentObject(authService)

                    // Плитки с основными действиями
                    ActionTilesGridView(
                        modalState: $modalState,
                        formState: $formState
                    )
                    .environmentObject(appState)

                    // Прогресс рабочего дня
                    ProgressDayView(
                        progressState: $progressState
                    )
                    .environmentObject(appState)

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
                    LogoutButton(showLogoutAlert: $showLogoutAlert)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    ScanQRButton(isShowingScanner: $modalState.isShowingScanner)
                }
            }
            .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
                Button("Выйти", role: .destructive) { authService.logout() }
                Button("Отмена", role: .cancel) {}
            }
            .alert(appState.alertMessage, isPresented: $appState.showAlert) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $modalState.isShowingScanner) {
                QRScannerSheet(
                    formState: $formState,
                    modalState: $modalState
                )
                .environmentObject(authService)
            }
            .sheet(isPresented: $modalState.isShowingTimePicker) {
                TimePickerSheet(
                    formState: $formState,
                    modalState: $modalState,
                    onConfirm: fetchAttendanceData
                )
                .environmentObject(ownDateService)
            }
            .sheet(isPresented: $modalState.isShowingOwnTypeList) {
                EventTypePickerSheet(
                    formState: $formState,
                    modalState: $modalState,
                    onConfirm: fetchAttendanceData
                )
                .environmentObject(ownDateService)
            }
            .sheet(isPresented: $modalState.isShowWorkItemPicker) {
                WorkItemPickerSheet(
                    formState: $formState,
                    modalState: $modalState,
                    onConfirm: fetchAttendanceData
                )
                .environmentObject(azureService)
            }
            .onAppear {
                setupOnAppear()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    // MARK: - Methods

    private func setupOnAppear() {
        notificationService.requestAuthorization { granted in }
        if authService.isAuthenticated {
            authService.fetchUserInfo { _ in }
            fetchAttendanceData()
        }
        startProgressTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.progressState.attendanceData == nil {
                self.fetchAttendanceData()
            }
        }
    }

    private func refreshData() async {
        await withCheckedContinuation { continuation in
            authService.fetchUserInfo { _ in
                continuation.resume()
            }
        }
        fetchAttendanceData()
    }

    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.fetchAttendanceData()  // Полностью обновляем данные вместо ручного расчета
        }
        // Первый запуск сразу
        timer?.fire()
    }

    private func fetchAttendanceData() {
        attendanceService.fetchAttendanceData { result in
            DispatchQueue.main.async {
                self.progressState.isLoading = false

                switch result {
                case .success(let attendanceResponse):
                    if let attendance = attendanceResponse {
                        self.progressState.attendanceData = attendance
                        self.progressState = self.attendanceService
                            .calculateWorkProgress(attendance: attendance)
                    } else {
                        self.progressState = self.attendanceService
                            .resetProgressValues()
                    }

                case .failure:
                    self.progressState = self.attendanceService
                        .resetProgressValues()
                }
            }
        }
    }
}
