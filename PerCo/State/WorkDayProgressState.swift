// состояния, связанные с таймером и прогрессом рабочего дня
struct WorkDayProgressState {
    var progress: Double = 0
    var timeWorked = "00:00"
    var timeRemaining = "08:30"
    var expectedFinishTime = "N/A"
    var isLoading = false
    var attendanceData: AttendanceResponse?
}
