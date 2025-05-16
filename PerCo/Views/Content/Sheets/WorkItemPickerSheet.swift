import SwiftUI

struct WorkItemPickerSheet: View {
    @EnvironmentObject var azureService: AzureService
    @Binding var formState: FormInputState
    @Binding var modalState: ModalSheetsState
    var onConfirm: () -> Void
    
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
            onCancel: { modalState.isShowWorkItemPicker = false },
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
                
                onConfirm()
                modalState.isShowWorkItemPicker = false
            }
        )
    }
}
