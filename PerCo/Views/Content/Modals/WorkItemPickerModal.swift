import SwiftUI

struct WorkItemPickerModal: View {
    @EnvironmentObject var azureService: AzureService
    @Binding var isPresented: Bool
    @Binding var formState: FormInputState
    var onDismiss: () -> Void
    
    var body: some View {
        WorkItemPickerView(
            hours: $formState.selectedHours,
            minutes: $formState.selectedMinutes,
            isRemoteWork: $formState.isRemoteWork,
            isOverTimeWork: $formState.isOverTimeWork,
            comment: $formState.comment,
            workType: $formState.selectedWorkType,
            projectScope: $formState.selectedProjectScope,
            selectedWorkItem: $formState.selectedWorkItem,
            onCancel: { isPresented = false },
            onConfirm: {
                guard let issue = formState.selectedWorkItem else { return }
                
                azureService.createTimeEntry(
                    workItemId: issue.workItemId,
                    hours: formState.selectedHours,
                    minutes: formState.selectedMinutes,
                    isRemoteWork: formState.isRemoteWork,
                    isOverTimeWork: formState.isOverTimeWork,
                    comment: formState.comment,
                    workType: formState.selectedWorkType,
                    projectScope: formState.selectedProjectScope
                )
                
                isPresented = false
                onDismiss()
            }
        )
    }
}
