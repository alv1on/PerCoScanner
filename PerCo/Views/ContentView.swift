import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var ownDateService: OwnDateService
    @EnvironmentObject var azureService: AzureService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationService: NotificationService
    
    // Состояния для управления UI
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    @State private var showLogoutAlert = false
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var isShowingTimePicker = false
    @State private var isShowWorkItemPicker = false
    @State private var isShowingOwnTypeList = false
    @State private var isRemoteWork = false
    @State private var isOverTimeWork = false
    @State private var comment = ""
    @State private var selectedWorkItem: WorkItem?
    @State private var timePickerType: String?
    @State private var selectedEmails: [String] = []
    @State private var selectedEventType = "OwnExpenses"
    @State private var selectedWorkType = ""
    @State private var selectedProjectScope = ""
    @State private var isScanButtonAnimating = false
    
    // Состояния для прогресса рабочего дня
    @State private var attendanceData: AttendanceResponse?
    @State private var isLoadingAttendance = false
    @State private var progress: Double = 0
    @State private var timeWorked = "00:00"
    @State private var timeRemaining = "08:30"
    @State private var expectedFinishTime = "N/A"
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Шапка с именем пользователя и датой
                    userHeaderView
                    
                    // Плитки с основными действиями
                    actionTilesGrid
                    
                    // Прогресс рабочего дня
                    progressDayView
                    
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
                    logoutButton
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    scanQRButton
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
                timePickerSheet
            }
            .sheet(isPresented: $isShowingOwnTypeList) {
                eventTypePickerSheet
            }
            .sheet(isPresented: $isShowWorkItemPicker) {
                workItemPickerSheet
            }
            .onAppear {
                setupOnAppear()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Subviews
    private var progressDayView: some View {
        WorkDayProgressView(
            progress: progress,
            timeWorked: timeWorked,
            timeRemaining: timeRemaining,
            expectedFinishTime: expectedFinishTime,
            isLoading: isLoadingAttendance
        )
        .padding(.horizontal)
    }
    
    private var userHeaderView: some View {
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
    
    private var actionTilesGrid: some View {
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
                icon: "plus.square.dashed",
                label: "Azure",
                action: {
                    comment = "Работа над задачей"
                    isShowWorkItemPicker = true
                },
                isLoading: appState.isLoading
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
    }
    
    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .blue)
        }
    }
    
    private var scanQRButton: some View {
        Button(action: { withAnimation { isShowingScanner = true } }) {
            Image(systemName: "qrcode.viewfinder")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .blue)
                .scaleEffect(isScanButtonAnimating ? 1.1 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                        isScanButtonAnimating.toggle()
                    }
                }
        }
    }
    
    private var timePickerSheet: some View {
        OwnDateView(
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
                fetchAttendanceData() // Обновляем данные после изменения
            }
        )
    }
    
    private var eventTypePickerSheet: some View {
        EventTypePickerView(
            selectedEventType: $selectedEventType,
            onCancel: { isShowingOwnTypeList = false },
            onConfirm: {
                ownDateService.createOwnDate(
                    type: selectedEventType,
                    hours: selectedHours,
                    minutes: selectedMinutes,
                    isRemoteWork: isRemoteWork,
                    selectedEmails: selectedEmails
                )
                isShowingOwnTypeList = false
                fetchAttendanceData() // Обновляем данные после изменения
            }
        )
    }
    
    private var workItemPickerSheet: some View {
        WorkItemPickerView(
            hours: $selectedHours,
            minutes: $selectedMinutes,
            isRemoteWork: $isRemoteWork,
            isOverTimeWork: $isOverTimeWork,
            comment: $comment,
            workType: $selectedWorkType,
            projectScope: $selectedProjectScope,
            selectedWorkItem: $selectedWorkItem,
            onCancel: { isShowWorkItemPicker = false },
            onConfirm: {
                guard let issue = selectedWorkItem else { return }
                
                azureService.createTimeEntry(
                    workItemId: issue.workItemId,
                    hours: selectedHours,
                    minutes: selectedMinutes,
                    isRemoteWork: isRemoteWork,
                    isOverTimeWork: isOverTimeWork,
                    comment: comment,
                    workType: selectedWorkType,
                    projectScope: selectedProjectScope
                )
                
                isShowWorkItemPicker = false
                fetchAttendanceData() // Обновляем данные после изменения
            }
        )
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
                if self.attendanceData == nil {
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
            self.fetchAttendanceData() // Полностью обновляем данные вместо ручного расчета
        }
        // Первый запуск сразу
        timer?.fire()
    }
    
    private func fetchAttendanceData() {
        guard authService.isAuthenticated else {
            resetProgressValues()
            return
        }
        
        isLoadingAttendance = true
        
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: today)
        
        // Создаем URL с параметрами запроса
        var urlComponents = URLComponents(string: ApiConfig.Attendance.attendance)
        urlComponents?.queryItems = [
            URLQueryItem(name: "extEmpIds", value: authService.employeeId),
            URLQueryItem(name: "beginDate", value: dateString),
            URLQueryItem(name: "endDate", value: dateString)
        ]
        
        guard let url = urlComponents?.url else {
            isLoadingAttendance = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoadingAttendance = false
                
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode([AttendanceResponse].self, from: data)
                        if let firstResponse = response.first {
                            self.attendanceData = firstResponse
                            self.calculateWorkProgress(attendance: firstResponse)
                        }
                    } catch {
                        print("Error decoding attendance data: \(error)")
                        // Устанавливаем значения по умолчанию при ошибке
                        self.attendanceData = nil
                        resetProgressValues()
                    }
                }
            }
        }.resume()
    }
    
    private func calculateWorkProgress(attendance: AttendanceResponse) {
        // 1. Парсим общее необходимое время (totalNeeded)
        let totalNeededComponents = attendance.totalNeeded.components(separatedBy: ":")
        guard totalNeededComponents.count == 3,
              let neededHours = Int(totalNeededComponents[0]),
              let neededMinutes = Int(totalNeededComponents[1]) else {
            resetProgressValues()
            return
        }
        let totalNeededMinutes = (neededHours * 60) + neededMinutes
        
        // 2. Парсим уже отработанное время (total)
        let totalComponents = attendance.total.components(separatedBy: ":")
        guard totalComponents.count == 3,
              let totalHours = Int(totalComponents[0]),
              let totalMinutes = Int(totalComponents[1]) else {
            resetProgressValues()
            return
        }
        let totalWorkedMinutes = (totalHours * 60) + totalMinutes
        
        // 3. Находим все события входа/выхода и сортируем по времени
        let events = attendance.attendances.first?.events.sorted {
            ($0.spentTime ?? "") < ($1.spentTime ?? "")
        } ?? []
        
        // 4. Определяем текущий статус (внутри или снаружи офиса)
        var isCurrentlyInside = false
        var lastEnterTime: String?
        var lastEnterDate: Date?
        
        for event in events {
            if event.type == "EnterManual" {
                isCurrentlyInside = true
                lastEnterTime = event.spentTime
            } else if event.type == "ExitManual" {
                isCurrentlyInside = false
            }
        }
        
        // 5. Если сейчас внутри офиса (есть незавершенная сессия)
        if isCurrentlyInside, let lastEnterTime = lastEnterTime {
            // Парсим время последнего входа
            let enterTimeComponents = lastEnterTime.components(separatedBy: ":")
            guard enterTimeComponents.count == 3,
                  let enterHours = Int(enterTimeComponents[0]),
                  let enterMinutes = Int(enterTimeComponents[1]) else {
                resetProgressValues()
                return
            }
            
            // Создаем дату последнего входа
            let calendar = Calendar.current
            let now = Date()
            lastEnterDate = calendar.date(bySettingHour: enterHours, minute: enterMinutes, second: 0, of: now) ?? now
            
            // Рассчитываем время с последнего входа
            let minutesSinceLastEnter = calendar.dateComponents([.minute], from: lastEnterDate!, to: now).minute ?? 0
            
            // Общее время работы = уже отработанное + время текущей сессии
            let totalWorkedWithCurrent = totalWorkedMinutes + minutesSinceLastEnter
            
            // Оставшееся время (может быть отрицательным если переработка)
            let remainingMinutes = totalNeededMinutes - totalWorkedWithCurrent
            
            // Расчет прогресса
            calculateAndDisplayProgress(
                totalWorked: totalWorkedWithCurrent,
                totalNeeded: totalNeededMinutes,
                remainingMinutes: remainingMinutes,
                lastEnterDate: lastEnterDate
            )
        } else {
            // 6. Если сейчас снаружи офиса
            let remainingMinutes = totalNeededMinutes - totalWorkedMinutes
            calculateAndDisplayProgress(
                totalWorked: totalWorkedMinutes,
                totalNeeded: totalNeededMinutes,
                remainingMinutes: remainingMinutes,
                lastEnterDate: nil
            )
        }
    }

    private func calculateAndDisplayProgress(
        totalWorked: Int,
        totalNeeded: Int,
        remainingMinutes: Int,
        lastEnterDate: Date?
    ) {
        // 1. Расчет прогресса (0...1)
        progress = min(max(Double(totalWorked) / Double(totalNeeded), 0), 1.0)
        
        // 2. Форматирование отработанного времени
        let hoursWorked = totalWorked / 60
        let minutesWorked = totalWorked % 60
        timeWorked = String(format: "%02d:%02d", hoursWorked, minutesWorked)
        
        // 3. Оставшееся время (абсолютное значение)
        let absRemaining = abs(remainingMinutes)
        let hoursRemaining = absRemaining / 60
        let minutesRemaining = absRemaining % 60
        
        if remainingMinutes > 0 {
            timeRemaining = String(format: "%02d:%02d", hoursRemaining, minutesRemaining)
        } else if remainingMinutes < 0 {
            timeRemaining = String(format: "+%02d:%02d", hoursRemaining, minutesRemaining)
        } else {
            timeRemaining = "00:00"
        }
        
        if remainingMinutes == 0 {
            notificationService.showWorkFinishedNotification()
        }
        
        // 4. Расчет времени окончания (только если внутри офиса и осталось время)
        if lastEnterDate != nil, remainingMinutes > 0 {
            if let finishDate = Calendar.current.date(byAdding: .minute, value: remainingMinutes, to: Date()) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                expectedFinishTime = formatter.string(from: finishDate)
            } else {
                expectedFinishTime = "N/A"
            }
        } else {
            expectedFinishTime = "N/A"
        }
    }

    private func resetProgressValues() {
        progress = 0
        timeWorked = "00:00"
        timeRemaining = "08:00"
        expectedFinishTime = "N/A"
    }
}
