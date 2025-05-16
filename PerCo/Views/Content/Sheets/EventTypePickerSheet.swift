import SwiftUI

struct EventTypePickerSheet: View {
    @EnvironmentObject var ownDateService: OwnDateService
    @Binding var formState: FormInputState
    @Binding var modalState: ModalSheetsState
    var onConfirm: () -> Void
    
    var body: some View {
        EventTypePickerView(
            selectedEventType: $formState.selectedEventType,
            onCancel: { modalState.isShowingOwnTypeList = false },
            onConfirm: {
                ownDateService.createOwnDate(
                    type: formState.selectedEventType,
                    hours: formState.selectedHours,
                    minutes: formState.selectedMinutes,
                    isRemoteWork: formState.isRemoteWork,
                    selectedEmails: formState.selectedEmails
                )
                onConfirm()
                modalState.isShowingOwnTypeList = false
            }
        )
    }
}
