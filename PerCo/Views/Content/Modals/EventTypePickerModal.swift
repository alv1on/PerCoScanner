import SwiftUI

struct EventTypePickerModal: View {
    @EnvironmentObject var ownDateService: OwnDateService
    @Binding var isPresented: Bool
    @Binding var formState: FormInputState
    var onDismiss: () -> Void
    
    var body: some View {
        EventTypePickerView(
            selectedEventType: $formState.selectedEventType,
            onCancel: { isPresented = false },
            onConfirm: {
                ownDateService.createOwnDate(
                    type: formState.selectedEventType,
                    hours: formState.selectedHours,
                    minutes: formState.selectedMinutes,
                    isRemoteWork: formState.isRemoteWork,
                    selectedEmails: formState.selectedEmails
                )
                isPresented = false
                onDismiss()
            }
        )
    }
}
