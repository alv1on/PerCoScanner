// состояния, связанные с формами
struct FormInputState {
    var selectedHours = 0
    var selectedMinutes = 0
    var isRemoteWork = false
    var isOverTimeWork = false
    var comment = ""
    var selectedEmails: [String] = []
    var selectedEventType = "OwnExpenses"
    var selectedWorkType = ""
    var selectedProjectScope = ""
    var timePickerType: String?
    var selectedWorkItem: WorkItem?
    var scannedCode: String?
}
