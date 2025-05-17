import SwiftUI

class AttendanceService: ObservableObject {
    private let authService: AuthService
    private let appState: AppState
    private let httpClient: HTTPClient

    init(authService: AuthService, appState: AppState, httpClient: HTTPClient) {
        self.authService = authService
        self.appState = appState
        self.httpClient = httpClient
    }

    func fetchAttendanceData(
        completion: @escaping (Result<AttendanceResponse?, Error>) -> Void
    ) {
        guard authService.isAuthenticated else {
            completion(.failure(NetworkError.unauthorized))
            return
        }

        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: today)

        // Создаем URL с параметрами запроса
        var urlComponents = URLComponents(
            string: ApiConfig.Attendance.attendance)
        urlComponents?.queryItems = [
            URLQueryItem(name: "extEmpIds", value: authService.employeeId),
            URLQueryItem(name: "beginDate", value: dateString),
            URLQueryItem(name: "endDate", value: dateString),
        ]

        guard let url = urlComponents?.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        httpClient.request(url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success((let data, _)):
                    do {
                        let response = try JSONDecoder().decode(
                            [AttendanceResponse].self, from: data)
                        completion(.success(response.first))
                    } catch {
                        self?.handleError(
                            message:
                                "Ошибка обработки данных посещаемости: \(error.localizedDescription)"
                        )
                        completion(.failure(error))
                    }

                case .failure(let error):
                    self?.handleNetworkError(error)
                    completion(.failure(error))
                }
            }
        }
    }

    func calculateWorkProgress(attendance: AttendanceResponse)
        -> WorkDayProgressState
    {
        _ = WorkDayProgressState()

        // 1. Парсим общее необходимое время (totalNeeded) из API
        let totalNeededComponents = attendance.totalNeeded.components(
            separatedBy: ":")
        guard totalNeededComponents.count == 3,
            let neededHours = Int(totalNeededComponents[0]),
            let neededMinutes = Int(totalNeededComponents[1])
        else {
            return resetProgressValues()
        }
        var totalNeededMinutes = (neededHours * 60) + neededMinutes
        
        let isTotalNeededZero = (neededHours == 0 && neededMinutes == 0)

        // 2. Парсим уже отработанное время (total)
        let totalComponents = attendance.total.components(separatedBy: ":")
        guard totalComponents.count == 3,
            let totalHours = Int(totalComponents[0]),
            let totalMinutes = Int(totalComponents[1])
        else {
            return resetProgressValues()
        }
        let totalWorkedMinutes = (totalHours * 60) + totalMinutes

        // 3. Парсим время вне офиса (totalOutTime)
        let totalOutComponents = attendance.totalOutTime.components(
            separatedBy: ":")
        let totalOutMinutesValue: Int
        if totalOutComponents.count == 3,
            let totalOutHours = Int(totalOutComponents[0]),
            let totalOutMinutes = Int(totalOutComponents[1])
        {
            totalOutMinutesValue = totalOutHours * 60 + totalOutMinutes
        } else {
            totalOutMinutesValue = 0
        }

        // 4. Проверяем условия для добавления 30 минут обеда
        if !isTotalNeededZero {
            let shouldAddLunchBreak =
                // Случай 1: Еще не было отметок (все нули)
                (totalWorkedMinutes == 0 && totalOutMinutesValue == 0)

                // Случай 2: Отработано больше 4 часов и время вне офиса ≤ 30 минут
                || (totalWorkedMinutes > 4 * 60 && totalOutMinutesValue < 30)

            if shouldAddLunchBreak {
                totalNeededMinutes += 30  // Добавляем 30 минут обеда
            }
        }

        // 5. Находим все события входа/выхода и сортируем по времени
        let events =
            attendance.attendances.first?.events.sorted {
                ($0.spentTime ?? "") < ($1.spentTime ?? "")
            } ?? []

        // 6. Определяем текущий статус (внутри или снаружи офиса)
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

        // 7. Если сейчас внутри офиса (есть незавершенная сессия)
        if isCurrentlyInside, let lastEnterTime = lastEnterTime {
            // Парсим время последнего входа
            let enterTimeComponents = lastEnterTime.components(separatedBy: ":")
            guard enterTimeComponents.count == 3,
                let enterHours = Int(enterTimeComponents[0]),
                let enterMinutes = Int(enterTimeComponents[1])
            else {
                return resetProgressValues()
            }

            // Создаем дату последнего входа
            let calendar = Calendar.current
            let now = Date()
            lastEnterDate =
                calendar.date(
                    bySettingHour: enterHours, minute: enterMinutes, second: 0,
                    of: now) ?? now

            // Рассчитываем время с последнего входа
            let minutesSinceLastEnter =
                calendar.dateComponents(
                    [.minute], from: lastEnterDate!, to: now
                ).minute ?? 0

            // Общее время работы = уже отработанное + время текущей сессии
            let totalWorkedWithCurrent =
                totalWorkedMinutes + minutesSinceLastEnter

            // Оставшееся время (может быть отрицательным если переработка)
            let remainingMinutes = totalNeededMinutes - totalWorkedWithCurrent

            // Расчет прогресса
            return calculateAndDisplayProgress(
                totalWorked: totalWorkedWithCurrent,
                totalNeeded: totalNeededMinutes,
                remainingMinutes: remainingMinutes,
                lastEnterDate: lastEnterDate
            )
        } else {
            // 8. Если сейчас снаружи офиса
            let remainingMinutes = totalNeededMinutes - totalWorkedMinutes
            return calculateAndDisplayProgress(
                totalWorked: totalWorkedMinutes,
                totalNeeded: totalNeededMinutes,
                remainingMinutes: remainingMinutes,
                lastEnterDate: nil
            )
        }
    }

    // MARK: - Вспомогательные методы
    private func calculateAndDisplayProgress(
        totalWorked: Int,
        totalNeeded: Int,
        remainingMinutes: Int,
        lastEnterDate: Date?
    ) -> WorkDayProgressState {
        var progressState = WorkDayProgressState()

        // 1. Расчет прогресса (0...1)
        progressState.progress = min(
            max(Double(totalWorked) / Double(totalNeeded), 0), 1.0)

        if totalNeeded == 0 {
            progressState.progress = 1.0
        }
        // 2. Форматирование отработанного времени
        let hoursWorked = totalWorked / 60
        let minutesWorked = totalWorked % 60
        progressState.timeWorked = String(
            format: "%02d:%02d", hoursWorked, minutesWorked)

        // 3. Оставшееся время (абсолютное значение)
        let absRemaining = abs(remainingMinutes)
        let hoursRemaining = absRemaining / 60
        let minutesRemaining = absRemaining % 60

        if remainingMinutes > 0 {
            progressState.timeRemaining = String(
                format: "%02d:%02d", hoursRemaining, minutesRemaining)
        } else if remainingMinutes < 0 {
            progressState.timeRemaining = String(
                format: "+%02d:%02d", hoursRemaining, minutesRemaining)
        } else {
            progressState.timeRemaining = "00:00"
        }

        // 4. Расчет времени окончания (только если внутри офиса и осталось время)
        if lastEnterDate != nil, remainingMinutes > 0 {
            if let finishDate = Calendar.current.date(
                byAdding: .minute, value: remainingMinutes, to: Date())
            {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                progressState.expectedFinishTime = formatter.string(
                    from: finishDate)
            } else {
                progressState.expectedFinishTime = "N/A"
            }
        } else {
            progressState.expectedFinishTime = "N/A"
        }

        return progressState
    }

    func resetProgressValues() -> WorkDayProgressState {
        var progressState = WorkDayProgressState()
        progressState.progress = 0
        progressState.timeWorked = "00:00"
        progressState.timeRemaining = "08:30"
        progressState.expectedFinishTime = "N/A"
        return progressState
    }

    private func handleNetworkError(_ error: Error) {
        switch error {
        case NetworkError.unauthorized:
            authService.handleUnauthorized()
        default:
            appState.alertMessage =
                "Ошибка загрузки данных посещаемости: \(error.localizedDescription)"
        }
        appState.showAlert = true
    }

    private func handleError(message: String) {
        appState.alertMessage = message
        appState.showAlert = true
    }
}
