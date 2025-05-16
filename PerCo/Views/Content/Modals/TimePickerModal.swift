import SwiftUI

struct TimePickerModal: View {
    @EnvironmentObject var ownDateService: OwnDateService
    @Binding var isPresented: Bool
    @Binding var formState: FormInputState
    var onDismiss: () -> Void
    
    var body: some View {
        OwnDateView(
            hours: $formState.selectedHours,
            minutes: $formState.selectedMinutes,
            isRemoteWork: $formState.isRemoteWork,
            selectedEmails: $formState.selectedEmails,
            onCancel: { isPresented = false },
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
                isPresented = false
                onDismiss()
            }
        )
    }
}
