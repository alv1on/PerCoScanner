import SwiftUI

struct TimePickerSheet: View {
    @EnvironmentObject var ownDateService: OwnDateService
    @Binding var formState: FormInputState
    @Binding var modalState: ModalSheetsState
    var onConfirm: () -> Void
    
    var body: some View {
        OwnDateView(
            hours: $formState.selectedHours,
            minutes: $formState.selectedMinutes,
            isRemoteWork: $formState.isRemoteWork,
            selectedEmails: $formState.selectedEmails,
            onCancel: { modalState.isShowingTimePicker = false },
            onConfirm: {
                if let type = formState.timePickerType {
                    ownDateService.createOwnDate(
                        type: type,
                        hours: formState.selectedHours,
                        minutes: formState.selectedMinutes,
                        isRemoteWork: formState.isRemoteWork,
                        selectedEmails: formState.selectedEmails
                    )
                }
                onConfirm()
                modalState.isShowingTimePicker = false
            }
        )
    }
}
