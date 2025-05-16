import SwiftUI

struct ActionTilesGridView: View {
    @EnvironmentObject var appState: AppState
    @Binding var modalState: ModalSheetsState
    @Binding var formState: FormInputState

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16
        ) {
            ActionTileView(
                icon: "calendar.badge.plus",
                label: "Начать день",
                action: {
                    formState.timePickerType = "EnterManual"
                    formState.selectedHours = 10
                    formState.selectedMinutes = 0
                    formState.isRemoteWork = false
                    modalState.isShowingTimePicker = true
                },
                isLoading: appState.isLoading
            )

            ActionTileView(
                icon: "plus.square.dashed",
                label: "Azure",
                action: {
                    formState.comment = "Работа над задачей"
                    modalState.isShowWorkItemPicker = true
                    formState.selectedHours = 0
                    formState.selectedMinutes = 0
                },
                isLoading: appState.isLoading
            )

            ActionTileView(
                icon: "calendar.badge.checkmark",
                label: "Закончить день",
                action: {
                    formState.timePickerType = "ExitManual"
                    formState.selectedHours = 18
                    formState.selectedMinutes = 30
                    formState.isRemoteWork = false
                    modalState.isShowingTimePicker = true
                },
                isLoading: appState.isLoading
            )

            ActionTileView(
                icon: "calendar.badge.exclamationmark",
                label: "Создать событие",
                action: {
                    modalState.isShowingOwnTypeList = true
                },
                isLoading: appState.isLoading
            )
        }
        .padding(.horizontal)
    }
}
