import SwiftUI

struct ProgressDayView: View {
    @EnvironmentObject var appState: AppState
    @Binding var progressState: WorkDayProgressState
    
    var body: some View {
        WorkDayProgressView(
            progress: progressState.progress,
            timeWorked: progressState.timeWorked,
            timeRemaining: progressState.timeRemaining,
            expectedFinishTime: progressState.expectedFinishTime,
            isLoading: appState.isLoading
        )
        .padding(.horizontal)
    }
}
